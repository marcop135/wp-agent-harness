/**
 * Self-hosted Matomo (mt.marcopontili.com, site 1): cookieless, Do Not Track
 * honoured, POST requests. Mirrors the marcopontili.com snippet.
 */
var _paq = (window._paq = window._paq || []);
_paq.push(['setDoNotTrack', true]);
_paq.push(['disableCookies']);
_paq.push(['setRequestMethod', 'POST']);
_paq.push(['trackPageView']);
_paq.push(['enableLinkTracking']);
(function () {
  var u = 'https://mt.marcopontili.com/';
  var p = 'm/';
  _paq.push(['setTrackerUrl', u + p]);
  _paq.push(['setSiteId', '1']);
  var d = document,
    g = d.createElement('script'),
    s = d.getElementsByTagName('script')[0];
  g.async = true;
  g.src = u + p;
  s.parentNode.insertBefore(g, s);
})();
