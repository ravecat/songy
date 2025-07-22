<style>
  .audio-bars {
    display: flex;
    gap: 3px;
    align-items: end;
    height: 40px;
  }
  
  .bar {
    width: 8.8px;
    background: white;
    border-radius: 4px;
    opacity: 0.7;
    animation: bounce 1.5s infinite ease-in-out;
  }
  
  .bar:nth-child(1) { animation-delay: 0.2s; animation-duration: 1.05s; }
  .bar:nth-child(2) { animation-delay: 0.4s; animation-duration: 1.35s; }
  .bar:nth-child(3) { animation-delay: 0.1s; animation-duration: 1.2s; }
  .bar:nth-child(4) { animation-delay: 0.5s; animation-duration: 0.9s; }
  .bar:nth-child(5) { animation-delay: 0.3s; animation-duration: 1.125s; }
  .bar:nth-child(6) { animation-delay: 0.6s; animation-duration: 1.1s; }
  .bar:nth-child(7) { animation-delay: 0.35s; animation-duration: 1.25s; }
  
  @keyframes bounce {
    0%, 80%, 100% {
      height: 8px;
    }
    40% {
      height: 40px;
    }
  }
</style>

<div class="flex flex-col items-center">
  <div class="audio-bars" role="status" aria-label="Loading">
    <div class="bar"></div>
    <div class="bar"></div>
    <div class="bar"></div>
    <div class="bar"></div>
    <div class="bar"></div>
    <div class="bar"></div>
    <div class="bar"></div>
  </div>
</div>
