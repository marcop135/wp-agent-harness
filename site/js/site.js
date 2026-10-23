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

/**
 * Plays an element on a loop while it is on screen and the tab is visible,
 * with a Pause/Play button. Only used when motion is allowed.
 */
function playLoop(root, toggle, label, timeline) {
  var index = 0;
  var timer = null;
  var paused = false;
  var visible = false;

  function schedule() {
    if (timer || paused || !visible || document.hidden) return;
    timer = window.setTimeout(function () {
      timer = null;
      timeline[index][1]();
      index = (index + 1) % timeline.length;
      schedule();
    }, timeline[index][0]);
  }

  function stop() {
    window.clearTimeout(timer);
    timer = null;
  }

  if (toggle) {
    toggle.hidden = false;
    toggle.addEventListener('click', function () {
      paused = !paused;
      root.classList.toggle('is-paused', paused);
      toggle.textContent = paused ? 'Play' : 'Pause';
      toggle.setAttribute('aria-label', (paused ? 'Play' : 'Pause') + ' the ' + label + ' animation');
      if (paused) stop();
      else schedule();
    });
  }

  document.addEventListener('visibilitychange', function () {
    if (document.hidden) stop();
    else schedule();
  });

  if ('IntersectionObserver' in window) {
    new IntersectionObserver(function (entries) {
      visible = entries[0].isIntersecting;
      if (visible) schedule();
      else stop();
    }, { threshold: 0.25 }).observe(root);
  } else {
    visible = true;
    schedule();
  }
}

/**
 * Quick start and "How a request travels": each stop lights up in turn,
 * its log lines appear, and a packet runs along the wire to the next stop.
 * Without motion everything stays visible at once.
 */
(function () {
  if (!window.matchMedia('(prefers-reduced-motion: no-preference)').matches) return;

  Array.prototype.forEach.call(document.querySelectorAll('.journey'), function (journey) {
    var stops = journey.querySelectorAll('.journey-stops > li');
    var lines = journey.querySelectorAll('.journey-log li');
    var label = journey.classList.contains('journey-setup') ? 'setup' : 'request';
    var timeline = [[600, reset]];

    function linesFor(stop) {
      return Array.prototype.filter.call(lines, function (line) {
        return line.getAttribute('data-stop') === String(stop);
      });
    }

    function show(line) {
      return function () {
        line.classList.add('is-on');
      };
    }

    function arrive(i) {
      return function () {
        Array.prototype.forEach.call(stops, function (stop, n) {
          stop.classList.toggle('is-on', n <= i);
          stop.classList.toggle('is-current', n === i);
        });
      };
    }

    function send(i) {
      return function () {
        stops[i].classList.add('is-sent');
      };
    }

    function reset() {
      journey.classList.remove('is-back');
      Array.prototype.forEach.call(stops, function (stop) {
        stop.classList.remove('is-on', 'is-current', 'is-sent');
      });
      Array.prototype.forEach.call(lines, function (line) {
        line.classList.remove('is-on');
      });
    }

    Array.prototype.forEach.call(stops, function (stop, i) {
      if (i > 0) timeline.push([1800, send(i - 1)]);
      timeline.push([i > 0 ? 700 : 500, arrive(i)]);
      linesFor(i).forEach(function (line, n) {
        timeline.push([n ? 650 : 200, show(line)]);
      });
    });

    var back = linesFor('back');
    if (back.length) {
      timeline.push([1800, function () {
        stops[stops.length - 1].classList.remove('is-current');
        journey.classList.add('is-back');
      }]);
      back.forEach(function (line) {
        timeline.push([900, show(line)]);
      });
    }
    timeline.push([3600, function () {}]);

    journey.classList.add('is-live');
    playLoop(journey, journey.querySelector('.journey-toggle'), label, timeline);
  });
})();
