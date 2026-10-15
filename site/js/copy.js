/**
 * Copy buttons for quick-start code blocks. Added only when the Clipboard API
 * exists, so no visitor sees a button that cannot work.
 */
(function () {
  if (!navigator.clipboard || !window.isSecureContext) return;
  var status = document.getElementById('copy-status');
  var blocks = document.querySelectorAll('.code[data-label]');
  Array.prototype.forEach.call(blocks, function (block) {
    var bar = block.querySelector('.code-bar');
    var code = block.querySelector('pre code');
    if (!bar || !code) return;
    var label = block.getAttribute('data-label');
    var btn = document.createElement('button');
    var timer;
    btn.type = 'button';
    btn.className = 'copy';
    btn.textContent = 'Copy';
    btn.setAttribute('aria-label', 'Copy ' + label);
    btn.addEventListener('click', function () {
      navigator.clipboard.writeText(code.textContent.replace(/\n+$/, '')).then(
        function () {
          btn.textContent = 'Copied';
          btn.setAttribute('data-state', 'done');
          if (status) status.textContent = label + ' copied to the clipboard.';
        },
        function () {
          btn.textContent = 'Select';
          if (status) status.textContent = 'Copy failed. Select the text and copy it by hand.';
        }
      );
      clearTimeout(timer);
      timer = setTimeout(function () {
        btn.textContent = 'Copy';
        btn.removeAttribute('data-state');
      }, 2000);
    });
    bar.appendChild(btn);
  });
})();
