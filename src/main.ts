import './style.css';
const view = new URLSearchParams(location.search).get('view');
if (view === 'camp') {
  void import('./camp');
} else if (view === 'training') {
  void import('./tactical');
} else if (view === 'battle') {
  void import('./battle').then(module => module.bootBattle());
} else {
  void import('./run');
}
