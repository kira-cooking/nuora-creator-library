const hooks = {
  outfit: {line:'“The outfit was fine. I was uncomfortable.”',overlay:'The outfit wasn’t the problem.',show:'At the mirror, pause between a tucked and untucked shirt. One natural adjustment, then look to camera. No belly close-up or before-and-after pose.',alt:'“Sometimes choosing an outfit is really about how your stomach feels.”',test:'Does a familiar clothing moment make the right viewer recognize herself?'},
  dinner: {line:'“I wanted to enjoy dinner without thinking about my stomach the whole time.”',overlay:'At dinner. Thinking about my stomach.',show:'Begin seated at a dinner table. Put your phone down, make one understated adjustment, then look to camera. Keep the scene ordinary.',alt:'“For some women, dinner means thinking about their stomach instead of enjoying the evening.”',test:'Does an everyday social moment connect more clearly than the clothing scene?'},
  decision: {line:'“Before you choose another gut supplement, turn the bottle around.”',overlay:'Before you choose, check this.',show:'Start with the real bottle in your hand. Turn it from the front to the label on the words “turn the bottle around.”',alt:'This line works as an explainer. You do not need to claim personal symptoms or results.',test:'Does a useful buying question earn more relevant attention than opening with discomfort?'}
};
document.querySelectorAll('[data-hook]').forEach(button => button.addEventListener('click', () => {
  const hook = hooks[button.dataset.hook];
  document.querySelectorAll('[data-hook]').forEach(item => item.setAttribute('aria-pressed',String(item === button)));
  for (const field of ['line','show','alt','test']) document.getElementById(`hook-${field}`).textContent = hook[field];
  document.getElementById('hook-overlay').textContent = `On-screen text: ${hook.overlay}`;
}));
const video = document.getElementById('finn');
document.querySelectorAll('[data-seek]').forEach(button => button.addEventListener('click', () => {
  const seek = () => { video.currentTime = Number(button.dataset.seek); video.pause(); };
  if (video.readyState >= 1) seek(); else video.addEventListener('loadedmetadata',seek,{once:true});
  video.scrollIntoView({block:'center',behavior:matchMedia('(prefers-reduced-motion: reduce)').matches?'auto':'smooth'});
  video.focus({preventScroll:true});
}));
