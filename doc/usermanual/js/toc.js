
function makeToc($targetElement) {
  function makeId(text) {
	  return text.replace(/[^_a-zA-Z0-9]+/ig, '_').toLowerCase();
  }

  var $sourceElement = $('body');
  
  var rootList = document.createElement('ul');
  var numberStack = [null];
  var curList = rootList;
  var curLevel = 0;
  
  $sourceElement.find('h1, h2, h3, h4, h5, h6').each(function(index, header) {
    var level = new Number(header.tagName.substr(1));
    
    while (curLevel < level) {
        curLevel += 1;
        numberStack[curLevel] = 0;
        
        var newList = document.createElement('ul');
        if (!curList.lastChild) {
            curList.appendChild(document.createElement('li'));
        }
        curList.lastChild.appendChild(newList);
        curList = newList;
    }
    while (curLevel > level) {
        curList = curList.parentNode.parentNode;
        curLevel -= 1;
    }
    
    numberStack[curLevel] += 1;
    
    var text = $(header).text();
    if (!header.id) {
        header.id = makeId(text);
    }
    
    var number = numberStack.slice(1, curLevel + 1).join('.');
    $(header).text(number + " " + text);
    
    var li = document.createElement('li');
    li.className = 'toc-' + header.tagName;
    var a = document.createElement('a');
    a.href = '#' + header.id;
    $(a).text(number + " " + text);
    li.appendChild(a);
    curList.appendChild(li);
  });
  
  $targetElement.append(rootList.firstChild.firstChild);
}

