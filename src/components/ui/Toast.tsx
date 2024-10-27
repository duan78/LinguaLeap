import React from 'react';

interface ToastOptions {
  duration?: number;
  type?: 'success' | 'error' | 'info';
}

class Toast {
  private container: HTMLDivElement | null = null;

  private createContainer() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.style.cssText = `
        position: fixed;
        top: 1rem;
        right: 1rem;
        z-index: 9999;
      `;
      document.body.appendChild(this.container);
    }
    return this.container;
  }

  private show(message: string, options: ToastOptions = {}) {
    const { duration = 3000, type = 'info' } = options;
    const container = this.createContainer();

    const toast = document.createElement('div');
    toast.className = `
      px-4 py-2 mb-2 rounded-lg shadow-lg
      ${type === 'error' ? 'bg-red-500' : type === 'success' ? 'bg-green-500' : 'bg-blue-500'}
      text-white text-sm font-medium
      transform transition-all duration-300 ease-in-out
    `;
    toast.textContent = message;

    container.appendChild(toast);

    // Animate in
    requestAnimationFrame(() => {
      toast.style.opacity = '1';
      toast.style.transform = 'translateX(0)';
    });

    // Remove after duration
    setTimeout(() => {
      toast.style.opacity = '0';
      toast.style.transform = 'translateX(100%)';
      setTimeout(() => {
        container.removeChild(toast);
        if (container.childNodes.length === 0) {
          document.body.removeChild(container);
          this.container = null;
        }
      }, 300);
    }, duration);
  }

  success(message: string, options?: Omit<ToastOptions, 'type'>) {
    this.show(message, { ...options, type: 'success' });
  }

  error(message: string, options?: Omit<ToastOptions, 'type'>) {
    this.show(message, { ...options, type: 'error' });
  }

  info(message: string, options?: Omit<ToastOptions, 'type'>) {
    this.show(message, { ...options, type: 'info' });
  }
}

export const toast = new Toast();