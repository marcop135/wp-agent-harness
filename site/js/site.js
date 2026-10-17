/**
 * Copy buttons on the quick-start snippets (write only, the clipboard is
 * never read) and the FAQ open and close animation.
 */
(function () {
  var status = document.getElementById('copy-status');

  function fallbackCopy(text) {
    var area = document.createElement('textarea');
    area.value = text;
    area.setAttribute('readonly', '');
    area.className = 'visually-hidden';
    document.body.appendChild(area);
    area.select();
    var ok = false;
    try {
      ok = document.execCommand('copy');
    } catch (e) {
      ok = false;
    }
    document.body.removeChild(area);
    return ok ? Promise.resolve() : Promise.reject(new Error('copy failed'));
  }

  function copyText(text) {
    if (navigator.clipboard && window.isSecureContext) {
      return navigator.clipboard.writeText(text).catch(function () {
        return fallbackCopy(text);
      });
    }
    return fallbackCopy(text);
  }

  function announce(message) {
    if (!status) return;
    status.textContent = '';
    window.setTimeout(function () {
      status.textContent = message;
    }, 50);
  }

  Array.prototype.forEach.call(document.querySelectorAll('[data-copy]'), function (button) {
    var label = button.querySelector('.copy-label');
    var source = document.getElementById(button.getAttribute('data-copy'));
    if (!source || !label) return;
    // Shell snippets end with a newline; prompts do not, so pasting one
    // into an agent does not send it.
    var suffix = source.closest('pre') ? '\n' : '';
    var timer;
    button.hidden = false;
    button.addEventListener('click', function () {
      copyText(source.textContent.replace(/\s+$/, '') + suffix).then(
        function () {
          button.setAttribute('data-state', 'done');
          label.textContent = 'Copied';
          announce(button.getAttribute('aria-label').replace(/^Copy/, 'Copied'));
        },
        function () {
          label.textContent = 'Select';
          announce('Copy failed. Select the text and copy it by hand.');
        }
      );
      window.clearTimeout(timer);
      timer = window.setTimeout(function () {
        button.removeAttribute('data-state');
        label.textContent = 'Copy';
      }, 2000);
    });
  });
})();

(function () {
  var motion = window.matchMedia('(prefers-reduced-motion: no-preference)');
  if (!('animate' in Element.prototype)) return;

  Array.prototype.forEach.call(document.querySelectorAll('.faq details'), function (item) {
    var summary = item.querySelector('summary');
    var running = null;
    var closing = false;

    summary.addEventListener('click', function (event) {
      if (!motion.matches) return;
      event.preventDefault();
      closing = running ? !closing : item.open;
      var from = item.offsetHeight;
      if (running) running.cancel();
      item.open = true;
      var to = closing ? summary.offsetHeight + 2 : item.offsetHeight;
      running = item.animate(
        { height: [from + 'px', to + 'px'] },
        { duration: 280, easing: 'cubic-bezier(0.22, 1, 0.36, 1)' }
      );
      running.onfinish = function () {
        running = null;
        if (closing) item.open = false;
      };
    });
  });
})();
