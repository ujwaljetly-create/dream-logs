"use strict";
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {defineSecret} = require("firebase-functions/params");
const {logger} = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();
const bucket = admin.storage().bucket();
const apiKey = defineSecret("OPENAI_API_KEY");

async function referencesFor(owner, castIds) {
  const result = [];
  const ids = [...new Set([owner, ...castIds.filter(x => typeof x === "string" && !x.startsWith("persona:"))])].slice(0, 3);
  for (const uid of ids) {
    if (uid !== owner) {
      const sent = await db.collection("castInvites").where("senderUid", "==", owner).get();
      const received = await db.collection("castInvites").where("recipientUid", "==", owner).get();
      const allowed = [...sent.docs, ...received.docs].some(d => {
        const v = d.data();
        return v.status === "accepted" && (v.senderUid === uid || v.recipientUid === uid);
      });
      if (!allowed) continue;
    }
    const photos = await db.collection("users").doc(uid).collection("dreamPhotos")
      .where("availableForDreams", "==", true).limit(1).get();
    if (photos.empty) continue;
    const path = photos.docs[0].data().storagePath;
    if (typeof path !== "string" || !path.startsWith("users/" + uid + "/dreamPhotos/")) continue;
    const [bytes] = await bucket.file(path).download();
    if (bytes.length <= 10 * 1024 * 1024) result.push(bytes);
  }
  return result;
}

exports.generateDreamStory = onDocumentCreated({
  document: "dreams/{dreamId}",
  region: "us-central1",
  timeoutSeconds: 540,
  memory: "1GiB",
  secrets: [apiKey],
  retry: false,
}, async event => {
  if (!event.data) return;
  const ref = event.data.ref;
  const data = event.data.data();
  if (data.status !== "queued" || data.type !== "story") return;
  const claimed = await db.runTransaction(async tx => {
    const fresh = await tx.get(ref);
    if (!fresh.exists || fresh.data().status !== "queued") return false;
    tx.update(ref, {status: "processing", startedAt: admin.firestore.FieldValue.serverTimestamp()});
    return true;
  });
  if (!claimed) return;

  try {
    const owner = data.ownerUid;
    const description = String(data.description || "").slice(0, 1500);
    const style = String(data.style || "Cinematic").slice(0, 40);
    const cast = Array.isArray(data.castIds) ? data.castIds : [];
    const references = await referencesFor(owner, cast);
    const prompt = "Create a beautiful " + style + " dream scene. Dream: " + description +
      ". Include the people described in the dream. If reference photos are provided, use them to portray distinct people with recognizable features. No watermark or text.";
    let response;
    if (references.length) {
      const form = new FormData();
      form.append("model", "gpt-image-1");
      form.append("prompt", prompt);
      form.append("size", "1024x1024");
      for (let i = 0; i < references.length; i++) {
        form.append("image[]", new Blob([references[i]], {type: "image/jpeg"}), "person_" + i + ".jpg");
      }
      response = await fetch("https://api.openai.com/v1/images/edits", {
        method: "POST", headers: {Authorization: "Bearer " + apiKey.value()}, body: form,
      });
    } else {
      response = await fetch("https://api.openai.com/v1/images/generations", {
        method: "POST",
        headers: {Authorization: "Bearer " + apiKey.value(), "Content-Type": "application/json"},
        body: JSON.stringify({model: "gpt-image-1", size: "1024x1024", prompt}),
      });
    }
    if (!response.ok) throw new Error("OpenAI HTTP " + response.status + ": " + (await response.text()).slice(0, 200));
    const json = await response.json();
    const encoded = json.data && json.data[0] && json.data[0].b64_json;
    if (!encoded) throw new Error("No image returned");
    const path = "dreams/" + owner + "/" + event.params.dreamId + "/scene_1.png";
    await bucket.file(path).save(Buffer.from(encoded, "base64"), {contentType: "image/png", resumable: false});
    await ref.update({status: "completed", scenes: [{storagePath: path, caption: description.slice(0, 200)}],
      completedAt: admin.firestore.FieldValue.serverTimestamp()});
  } catch (err) {
    logger.error("Dream generation failed", {dreamId: event.params.dreamId, message: err.message});
    await ref.update({status: "failed", error: "Image generation failed. Check backend logs.",
      completedAt: admin.firestore.FieldValue.serverTimestamp()});
  }
});
