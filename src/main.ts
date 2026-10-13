import './style.css';
if (new URLSearchParams(location.search).get('view') === 'camp') {
  void import('./camp');
} else {
  void import('./tactical');
}
