// current page
var pageNumber = 1;
// if page is rendering
var page_is_rendering = false;
// if another page is pending for rendering
var pageNumIsPending = null;
// width of the page, always updated
var page_width = window.innerWidth;
// Aspet ratio of the book currently loaded
var book_aspect_ratio = 1;
// true until the first render is performed
var first_render = true;
// hammer manager
var mc = undefined;
// pdfjs document
var doc = undefined;
// outline points
var outline = [];
// total number of pages in the book
var number_of_pages = 0;
// scale to use for rendering when doing it the fast way
var fast_scale = 1.5;

// BOOK PAGE API

function statusUpdate() {
	// for the chapter, scroll throught the chapters to find the right one if any
	let chap = -1;
	for(let i=0; i<outline.length; i++) {
		if(outline[i].src <= pageNumber)
			chap = outline[i].src;
		else
			break;
	}
	console.log("chapter " + JSON.stringify(chap));
	console.log("pageNumber " + pageNumber);
	console.log("UpdatePage");
}
function moveToPageRelative (num) {
	let target = pageNumber + Number(num);
	if(target < 1)
		target = 1;
	else if(target > number_of_pages)
		target = number_of_pages;
	
	// Don't trigger turning if it's the same page
	if(target != pageNumber) {
		if(Math.abs(target - pageNumber) > 1)
			console.log("Jumping " + JSON.stringify({pageNumber: pageNumber}) + " " + JSON.stringify({pageNumber: target}))
		
		// animation
		let fast_canvas = document.getElementById('fast-canvas');
		let slow_canvas = document.getElementById('slow-canvas');
		let move_canvas = document.getElementById('move-canvas');
			
		if(num == 1) {
			let next_canvas = document.getElementById('next-cache-canvas');
			
			next_canvas.width = slow_canvas.width;
			next_canvas.height = slow_canvas.height;
			
			fast_canvas.width = slow_canvas.width;
			fast_canvas.height = slow_canvas.height;
			fast_canvas.style.top = slow_canvas.style.top;
			fast_canvas.style.width = slow_canvas.style.width;
			fast_canvas.style.height = slow_canvas.style.height;
			fast_canvas.getContext('2d').drawImage(next_canvas, 0, 0);
			
			fastForeground();
			
			move_canvas.width = slow_canvas.width;
			move_canvas.height = slow_canvas.height;
			move_canvas.style.zIndex = 99;
			move_canvas.getContext('2d').drawImage(slow_canvas, 0, 0);
			move_canvas.classList.add("transitionPageOut");
			move_canvas.style.left = "-100%";
		} else if (num == -1) {
			let prev_canvas = document.getElementById('prev-cache-canvas');
		
			prev_canvas.width = slow_canvas.width;
			prev_canvas.height = slow_canvas.height;
			
			move_canvas.width = slow_canvas.width;
			move_canvas.height = slow_canvas.height;
			move_canvas.style.top = slow_canvas.style.top;
			move_canvas.style.width = slow_canvas.style.width;
			move_canvas.style.height = slow_canvas.style.height;
			move_canvas.style.left = "-100%";
			move_canvas.getContext('2d').drawImage(prev_canvas, 0, 0);
			move_canvas.style.zIndex = 99;
			
			fast_canvas.width = slow_canvas.width;
			fast_canvas.height = slow_canvas.height;
			fast_canvas.style.top = slow_canvas.style.top;
			fast_canvas.style.width = slow_canvas.style.width;
			fast_canvas.style.height = slow_canvas.style.height;
			fast_canvas.getContext('2d').drawImage(slow_canvas, 0, 0);
			
			fastForeground();
			
			move_canvas.classList.add("transitionPageOut");
			setTimeout (() => {
				move_canvas.style.left = "0%";
			}, 42);
		}
		
		queueRenderPage(target);
	}
}
function moveToLocus(locus) {
	queueRenderPage(locus.pageNumber);
}
function moveToChapter(chap) {
	console.log("Jumping " + JSON.stringify({pageNumber: pageNumber}) + " " + JSON.stringify({pageNumber: Number(chap)}));
	queueRenderPage(Number(chap));
}
var styleManager = {

	updateStyles: function(style){
		if(style.background)
			document.body.style.background = style.background;
		console.log("ok");
	}
}
// END BOOK PAGE CALLS

// this function clears the content of the canvas with name given
function canvasClear(name) {
	let cnv = document.getElementById(name);
	cnv.getContext('2d').clearRect(0, 0, cnv.width, cnv.height);
}

function slowForeground(){
	document.getElementById("slow-canvas").style.zIndex = "1";
	document.getElementById("fast-canvas").style.zIndex = "0";
}

function fastForeground(){
	document.getElementById("slow-canvas").style.zIndex = "0";
	document.getElementById("fast-canvas").style.zIndex = "1";
}

function centerCanvas(){
	var slow_canvas = document.getElementById("slow-canvas");
	var fast_canvas = document.getElementById("fast-canvas");
	var move_canvas = document.getElementById("move-canvas");
	if(window.innerWidth / window.innerHeight < book_aspect_ratio) {
		slow_canvas.style.top = "50%";
		slow_canvas.style.transform = "translateY(-50%)";
		fast_canvas.style.top = "50%";
		fast_canvas.style.transform = "translateY(-50%)";
		move_canvas.style.top = "50%";
		move_canvas.style.transform = "translateY(-50%)";
	} else {
		slow_canvas.style.top = "0px";
		slow_canvas.style.transform = "translateY(-0px)";
		fast_canvas.style.top = "0px";
		fast_canvas.style.transform = "translateY(-0px)";
		move_canvas.style.top = "0px";
		move_canvas.style.transform = "translateY(-0px)";
	}
}

// renders the page at the given scale in the given canvas, you also give success and fail callbacks
// note: scale -1 means automatic
function renderPage(target_page, scale, canvas_name, success, fail) {
	doc.getPage(target_page).then(
		function(page) {
			var sane_scale = scale;
			if(scale == -1) sane_scale = Math.min(5, Math.max(3, page_width / page.getViewport({scale: 1}).width));
			var viewport = page.getViewport({ scale: sane_scale });
			if(first_render) book_aspect_ratio = viewport.width / viewport.height;
			var canvas = document.getElementById(canvas_name);
			canvas.height = viewport.height;
			canvas.width = viewport.width;
			var renderContext = {
				canvasContext: canvas.getContext('2d'),
				viewport: viewport,
				enableWebGL: true
			}
			page.render(renderContext).promise.then(success, fail);
		}, fail
	)
}

// renders previous and next page (fast) in cache canvases
function updateCache() {
	// clear old cache
	canvasClear("next-cache-canvas");
	canvasClear("prev-cache-canvas");
	
	// find the pages to cache (next, previous) (relative values)
	// TODO: optimize all this stuff
	if(pageNumber > 1)
		renderPage(pageNumber-1, fast_scale, "prev-cache-canvas", ()=>{}, (reason)=>console.log("# Failed to render cache: " + reason));
	if(pageNumber < number_of_pages)
		renderPage(pageNumber+1, fast_scale, "next-cache-canvas", ()=>{}, (reason)=>console.log("# Failed to render cache: " + reason));
}

// callback after rendering a page
function renderCallback() {
	// set up canvases
	slowForeground();
	centerCanvas();
	
	// Communicate with QML stuff
	if(first_render) {
		first_render = false;
		console.log("Ready");
	}
	console.log("status_requested");
	
	updateCache();
	
	// if there is another page to render, render it
	if (pageNumIsPending !== null) {
		var temp_next_page = pageNumIsPending;
		pageNumIsPending = null;
		pageNumber = temp_next_page;
		renderPage(temp_next_page, -1, 'slow-canvas', renderCallback, renderFailCallback);
	}
}
function renderFailCallback(reason) { console.log("page rendering failed: " + reason); }

function queueRenderPage (num) {
    if (page_is_rendering) {
        pageNumIsPending = num;
    } else {
		page_is_rendering = true;
		pageNumber = num;
        renderPage(num, -1, 'slow-canvas', renderCallback, renderFailCallback);
		page_is_rendering = false;
    }
};

function tapPageTurn(ev) {
	// do not move if zoomed
	if(window.visualViewport.scale > 1.001) return;
	
	if(ev.center.x > window.innerWidth * 0.4)
		moveToPageRelative(1);
	else
		moveToPageRelative(-1);
}

async function parseOutlineNode(ol, depth) {
	const dest = ol.dest;
	let o_title = ol.title;
	let o_pageNumber = 1;
		
	var ref = dest[0];
		
	if(typeof(dest) === "string") {
		try {
			var destination = await doc.getDestination(dest);
			ref = destination[0];
		} catch(err) {
			console.log("# getDestination error: " + err);
		}
	}
	
	try {
		o_pageNumber = 1 + await doc.getPageIndex(ref);
	} catch(err) {
		console.log("# getPageIndex error: " + err);
	}
	
	outline.push({title: o_title, src: o_pageNumber, level: depth});
	
	// analize child
	await parseOutlineNodeArray(ol.items, depth+1);
}

async function parseOutlineNodeArray(ol, depth) {
	for (let i=0; i < ol.length; i++) {
		await parseOutlineNode(ol[i], depth);
	}
}

function transitionPageTurned() {
	let move_canvas = document.getElementById("move-canvas");
	move_canvas.classList.remove("transitionPageOut");
	move_canvas.style.zIndex = "-99";
	move_canvas.style.left = "0px";
	canvasClear("fast-canvas");
	canvasClear("move-canvas");
}

window.onload = function() {
	
	// initalize canvas
	document.getElementById("next-cache-canvas").style.visibility = "hidden";
	document.getElementById("prev-cache-canvas").style.visibility = "hidden";
	document.getElementById("move-canvas").style.zIndex = "-99";
	
	// initialize gestures
	mc = new Hammer.Manager(document.getElementById("container"));
	var Tap = new Hammer.Tap();
	var Press = new Hammer.Press();
	// Add the recognizer to the manager
	mc.add(Press);
	mc.add(Tap);
	mc.on("tap press", (ev) => tapPageTurn(ev) );
	
	// initialize event listeners
	document.getElementById("move-canvas").addEventListener("transitionend", transitionPageTurned);
	
	// load saved page or open from the beginning
	if(SAVED_PLACE && SAVED_PLACE.pageNumber)
		pageNumber = SAVED_PLACE.pageNumber;
	
	// load file and render first page
	pdfjsLib.GlobalWorkerOptions.workerSrc = '.pdfjs/build/pdf.worker.js';
	pdfjsLib.getDocument("book.pdf").promise.then(
		function(pdf_obj) {
			// init stuff
			doc = pdf_obj;
			first_render = true;
			number_of_pages = doc.numPages;
			console.log("numberOfPages " + number_of_pages);
			
			// populate content
			doc.getOutline().then( function(ol) {
				if(!ol) return;
				
				parseOutlineNodeArray(ol, 0).then( () => console.log("setContent " + JSON.stringify(outline)), ()=> console.log("# Error 414234") );
				
			}, (reason) => console.log("# cannot fetch outline: " + reason) );
			
			// render
			queueRenderPage(pageNumber);
		}, (reason) => console.log("# file loading failed: " + reason)
	);
}
window.onresize = function() {
	if(!doc) return;

	var past_width = page_width
	page_width = window.innerWidth
	
	centerCanvas();
	
	// trigger a background rendering if resolution increase
	if(window.innerWidth > past_width)
		queueRenderPage(pageNumber);
}
