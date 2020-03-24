const numItemsToGenerate = 10;

function renderItem(){
  fetch(`https://source.unsplash.com/user/steinbrueckri/400x400`).then((response)=> {
    
    console.log(response.url);
    let item = document.createElement('div');
    item.classList.add('item');
    item.innerHTML = `
      <img class="beach-image" src="${response.url}" alt="beach image"/>
    `     
    const gallery = document.getElementById("unsplash-gallery");
    gallery.appendChild(item);
  }) 
}
for(let i=0;i<numItemsToGenerate;i++){
  renderItem();
}
