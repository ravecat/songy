import "@testing-library/jest-dom";

// Mock dialog methods for jsdom compatibility
if (typeof HTMLDialogElement !== 'undefined') {
  HTMLDialogElement.prototype.showModal = HTMLDialogElement.prototype.showModal || function() {
    this.setAttribute('open', '');
  };
  
  HTMLDialogElement.prototype.close = HTMLDialogElement.prototype.close || function() {
    this.removeAttribute('open');
  };
  
  HTMLDialogElement.prototype.show = HTMLDialogElement.prototype.show || function() {
    this.setAttribute('open', '');
  };
}

if (typeof Element !== 'undefined' && !Element.prototype.animate) {
  Element.prototype.animate = function () {
    return {
      cancel: () => {},
      finish: () => {},
      addEventListener: () => {},
      removeEventListener: () => {},
      finished: Promise.resolve(),
    };
  };
}

if (typeof document !== 'undefined') {
  const style = document.createElement('style');
  style.textContent = '.btn { display: flex; }';
  document.head.appendChild(style);
}
