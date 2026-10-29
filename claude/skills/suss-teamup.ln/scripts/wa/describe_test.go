package main

import (
	"testing"

	"go.mau.fi/whatsmeow/proto/waE2E"
	"go.mau.fi/whatsmeow/types"
	"go.mau.fi/whatsmeow/types/events"
	"google.golang.org/protobuf/proto"
)

func TestDescribeMessage(t *testing.T) {
	cases := []struct {
		name, mediaType, want string
		content               *waE2E.Message
	}{
		{"plain text", "", "hi", &waE2E.Message{Conversation: proto.String("hi")}},
		{"link preview", "url", "see https://x.io", &waE2E.Message{ExtendedTextMessage: &waE2E.ExtendedTextMessage{Text: proto.String("see https://x.io"), Title: proto.String("X")}}},
		{"wrapped link", "url", "wrapped https://x.io", &waE2E.Message{EphemeralMessage: &waE2E.FutureProofMessage{Message: &waE2E.Message{ExtendedTextMessage: &waE2E.ExtendedTextMessage{Text: proto.String("wrapped https://x.io")}}}}},
		{"image with caption", "image", "[image] look", &waE2E.Message{ImageMessage: &waE2E.ImageMessage{Caption: proto.String("look")}}},
		{"image without caption", "image", "[image]", &waE2E.Message{ImageMessage: &waE2E.ImageMessage{}}},
	}
	for _, c := range cases {
		message := &events.Message{Info: types.MessageInfo{MediaType: c.mediaType}, Message: c.content}
		if got := describeMessage(message); got != c.want {
			t.Errorf("%s: got %q, want %q", c.name, got, c.want)
		}
	}
}

func TestHasWords(t *testing.T) {
	for text, want := range map[string]bool{"❤️": false, "🔥👍": false, "כנ״ל": true, "ok 👍": true} {
		if got := hasWords(text); got != want {
			t.Errorf("hasWords(%q) = %v, want %v", text, got, want)
		}
	}
}

func TestCaptionOf(t *testing.T) {
	for text, want := range map[string]string{"[image]": "", "[image] look": " look", "plain": "plain", "[gif]": ""} {
		if got := captionOf(text); got != want {
			t.Errorf("captionOf(%q) = %q, want %q", text, got, want)
		}
	}
}

func TestHasContent(t *testing.T) {
	keyOnly := &waE2E.Message{SenderKeyDistributionMessage: &waE2E.SenderKeyDistributionMessage{GroupID: proto.String("g")}}
	video := &waE2E.Message{SenderKeyDistributionMessage: keyOnly.SenderKeyDistributionMessage, VideoMessage: &waE2E.VideoMessage{}}
	if hasContent(keyOnly.ProtoReflect()) {
		t.Error("a key-distribution-only message has no content")
	}
	if !hasContent(video.ProtoReflect()) {
		t.Error("a video next to its key distribution has content")
	}
}
