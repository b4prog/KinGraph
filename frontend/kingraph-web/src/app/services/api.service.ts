import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { catchError, type Observable, throwError } from 'rxjs';

export interface InfoResponse {
  name: string;
  version: string;
  env: string | null;
}

@Injectable({ providedIn: 'root' })
export class ApiService {
  private readonly http = inject(HttpClient);
  // In dev, the Angular dev server runs on 4200; backend on 8080.
  // Configure NG_APP_API_URL via .env files or build-time environment variables.
  // Defaults to http://localhost:8080 for local development.
  private readonly baseUrl = import.meta.env?.NG_APP_API_URL || 'http://localhost:8080';

  getInfo(): Observable<InfoResponse> {
    return this.http.get<InfoResponse>(`${this.baseUrl}/api/v1/info`).pipe(
      catchError((error) => {
        console.error('Failed to fetch info:', error);
        return throwError(() => error);
      }),
    );
  }
}
