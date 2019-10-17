window.addEventListener("DOMContentLoaded", () => {
  document.querySelector(".scbd-filter").onclick = (evt) => {
    var filter = evt.target.getAttribute('data-filter');
    if(evt.target.classList.contains('enabled')) {
      var num_enabled = 0;
      document.querySelectorAll('.filter-entry').forEach(el => {
        if(el.classList.contains('enabled')) num_enabled++;
      });
      if(num_enabled <= 1) return;
      evt.target.classList.replace('enabled', 'disabled');
      document.querySelectorAll('tr.' + filter).forEach(el => {
        el.style.display = 'none';
      })
    } else {
      evt.target.classList.replace('disabled', 'enabled');
      document.querySelectorAll('tr.' + filter).forEach(el => {
        el.style.display = '';
      })
    }
  };
});
