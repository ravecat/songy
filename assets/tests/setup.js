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
