package httpserver

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
)

var (
	appName    = "KinGraph"
	appVersion = "0.1.0"
)

type infoPayload struct {
	Name    string  `json:"name"`
	Version string  `json:"version"`
	Env     *string `json:"env"`
}

func healthzHandler(w http.ResponseWriter, r *http.Request) {
	withCORS(w, r)
	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusNoContent)
		return
	}
	if r.Method != http.MethodGet && r.Method != http.MethodHead {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	if r.Method != http.MethodHead {
		if _, err := w.Write([]byte("ok")); err != nil {
			log.Printf("healthz: failed to write response: %v", err)
		}
	}
}

func infoHandler(w http.ResponseWriter, r *http.Request) {
	withCORS(w, r)
	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusNoContent)
		return
	}
	if r.Method != http.MethodGet && r.Method != http.MethodHead {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	env := os.Getenv("KIN_GRAPH_ENV")
	var envPtr *string
	if env != "" {
		envPtr = &env
	}
	resp := infoPayload{Name: appName, Version: appVersion, Env: envPtr}
	if r.Method != http.MethodHead {
		b, err := json.Marshal(resp)
		if err != nil {
			log.Printf("infoHandler: failed to encode response: %v", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusOK)
		if _, err := w.Write(b); err != nil {
			log.Printf("infoHandler: failed to write response: %v", err)
		}
	}
}
