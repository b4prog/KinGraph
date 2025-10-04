package httpserver

import (
	"net/http"
)

// NewRouter returns the HTTP router configured with all KinGraph routes,
// middleware, and handlers. The returned http.Handler is safe to use
// with an http.Server.
//
// Callers typically pass the result to http.Server{Handler: ...} or http.ListenAndServe.
func NewRouter() http.Handler {
	mux := http.NewServeMux()

	mux.HandleFunc("GET /healthz", healthzHandler)
	mux.HandleFunc("GET /api/v1/info", infoHandler)

	// CORS preflight for all paths
	mux.HandleFunc("OPTIONS /{path...}", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	})

	return withCommonMiddleware(mux)
}
