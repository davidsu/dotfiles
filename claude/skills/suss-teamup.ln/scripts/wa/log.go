package main

import (
	"bufio"
	"encoding/json"
	"errors"
	"io/fs"
	"os"
	"sync"
	"time"
)

type entry struct {
	ID      string    `json:"id"`
	Time    time.Time `json:"time"`
	Group   string    `json:"group"`
	Sender  string    `json:"sender"`
	Name    string    `json:"name,omitempty"`
	ByMe    bool      `json:"by_me,omitempty"`
	Text    string    `json:"text"`
	History bool      `json:"history,omitempty"`
}

type messageLog struct {
	mu   sync.Mutex
	path string
	seen map[string]bool
}

func openMessageLog(path string) (*messageLog, error) {
	seen, err := readSeenIDs(path)
	return &messageLog{path: path, seen: seen}, err
}

func readSeenIDs(path string) (map[string]bool, error) {
	seen := map[string]bool{}
	file, err := os.Open(path)
	if errors.Is(err, fs.ErrNotExist) {
		return seen, nil
	}
	if err != nil {
		return nil, err
	}
	defer file.Close()
	lines := bufio.NewScanner(file)
	lines.Buffer(make([]byte, 1<<20), 1<<20)
	for lines.Scan() {
		var logged entry
		if json.Unmarshal(lines.Bytes(), &logged) == nil {
			seen[logged.ID] = true
		}
	}
	return seen, lines.Err()
}

func (messages *messageLog) record(logged entry) (bool, error) {
	messages.mu.Lock()
	defer messages.mu.Unlock()
	if messages.seen[logged.ID] {
		return false, nil
	}
	line, err := json.Marshal(logged)
	if err != nil {
		return false, err
	}
	file, err := os.OpenFile(messages.path, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o600)
	if err != nil {
		return false, err
	}
	defer file.Close()
	if _, err := file.Write(append(line, '\n')); err != nil {
		return false, err
	}
	messages.seen[logged.ID] = true
	return true, nil
}
