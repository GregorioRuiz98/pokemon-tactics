import './style.css';
const view = new URLSearchParams(location.search).get('view');
if (view === 'camp') {
  void import('./camp');
} else if (view === 'training') {
  void import('./tactical');
} else {
  void import('./battle');
}
