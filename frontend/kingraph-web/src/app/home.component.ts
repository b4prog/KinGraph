import { Component, DestroyRef, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { CommonModule } from '@angular/common';
import { ApiService, InfoResponse } from './services/api.service';
import { switchMap, Subject } from 'rxjs';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule],
  template: `
    <main class="container">
      <h1>KinGraph</h1>
      <button (click)="load()">Call Backend</button>

      @if (info(); as i) {
        <pre>{{ i | json }}</pre>
      }
      @if (error()) {
        <p>{{ error() }}</p>
      }
    </main>
  `,
  styles: [
    `
      .container {
        max-width: 960px;
        margin: 2rem auto;
        padding: 0 1rem;
      }
      button {
        padding: 0.5rem 1rem;
      }
      pre {
        background: #111;
        color: #eee;
        padding: 1rem;
        border-radius: 8px;
      }
    `,
  ],
})
export class HomeComponent {
  private readonly api = inject(ApiService);
  readonly info = signal<InfoResponse | null>(null);
  readonly error = signal<string | null>(null);
  readonly loading = signal<boolean>(false);
  private readonly destroyRef = inject(DestroyRef);
  private readonly loadTrigger = new Subject<void>();

  constructor() {
    this.loadTrigger
      .pipe(
        switchMap(() => {
          this.loading.set(true);
          this.error.set(null);
          return this.api.getInfo();
        }),
        takeUntilDestroyed(this.destroyRef),
      )
      .subscribe({
        next: (data) => {
          this.loading.set(false);
          this.info.set(data);
        },
        error: (e) => {
          this.loading.set(false);
          const message = e?.error?.message || e?.message || 'An unexpected error occurred';
          this.error.set(message);
        },
      });
  }

  load() {
    this.loadTrigger.next();
  }
}
