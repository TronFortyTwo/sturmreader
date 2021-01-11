// current page
var pageNumber = 1;
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
// if next page and previous one are ready
var next_canvas_ready = false;
var prev_canvas_ready = false;
// if a page turning is already ongoing, and we ignore other turns
var ignore_page_turning = false;

// helper function, pause execution for s milliseconds
function sleep(s){
	var now = new Date().getTime();
	while( new Date().getTime() < now + (s) ) {}
}

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
function moveToPageRelative(num) {
	moveToPage(pageNumber + Number(num), false);
}
function moveToLocus(locus) {
	moveToPage(locus.pageNumber, false);
}
function moveToChapter(chap) {
	moveToPage(Number(chap), false);
}
var styleManager = {
	updateStyles: function(style){
		if(style.background)
			document.body.style.background = style.background;
		console.log("ok");
	}
}
// END BOOK PAGE CALLS

function moveToPage(target, force_and_silent) {
	// sanitize
	if(target < 1)
		target = 1;
	else if(target > number_of_pages)
		target = number_of_pages;
	
	// Don't trigger turning if it's the same page
	// In theory ignore_page_turning and force_and_silent should never conflict
	if((target != pageNumber && !ignore_page_turning) || force_and_silent) {
		
		ignore_page_turning = true;
		
		let delta = target - pageNumber;
		
		if(Math.abs(delta) > 1 && !force_and_silent)
			console.log("Jumping " + JSON.stringify({pageNumber: pageNumber}) + " " + JSON.stringify({pageNumber: target}))
		
		// update page number
		pageNumber = target;
		
		// our canvases
		let slow_canvas = document.getElementById('slow-canvas');
		let move_canvas = document.getElementById('move-canvas');
		let next_canvas = document.getElementById('next-cache-canvas');
		let prev_canvas = document.getElementById('prev-cache-canvas');
		
		// one page forward
		if(delta == 1) {
			// moving canvas will display old page
			move_canvas.width = slow_canvas.width;
			move_canvas.height = slow_canvas.height;
			move_canvas.getContext('2d').clearRect(0, 0, move_canvas.width, move_canvas.height);
			move_canvas.getContext('2d').drawImage(slow_canvas, 0, 0);
			
			// prev page will be current one
			prev_canvas.width = slow_canvas.width;
			prev_canvas.height = slow_canvas.height;
			prev_canvas.getContext('2d').clearRect(0, 0, prev_canvas.width, prev_canvas.height);
			prev_canvas.getContext('2d').drawImage(slow_canvas, 0, 0);
			
			// slow canvas will display new page
			slow_canvas.width = next_canvas.width;
			slow_canvas.height = next_canvas.height;
			
			function whenNextCanvasReady() {
				if(next_canvas_ready) {
					slow_canvas.getContext('2d').clearRect(0, 0, slow_canvas.width, slow_canvas.height);
					slow_canvas.getContext('2d').drawImage(next_canvas, 0, 0);
			
					// move canvas
					move_canvas.style.zIndex = 99;
					move_canvas.classList.add("transitionPageOut");
					move_canvas.style.left = "-100%";
			
					// render new next page
					next_canvas_ready = false;
			
					afterRendering();
				}
				else setTimeout(whenNextCanvasReady, 20 );
			}
			whenNextCanvasReady();
		}
		// one page back
		else if (delta == -1) {
			// moving canvas will display old page
			move_canvas.width = slow_canvas.width;
			move_canvas.height = slow_canvas.height;
			move_canvas.getContext('2d').clearRect(0, 0, move_canvas.width, move_canvas.height);
			move_canvas.getContext('2d').drawImage(slow_canvas, 0, 0);
			
			// next page will be current one
			next_canvas.width = slow_canvas.width;
			next_canvas.height = slow_canvas.height;
			next_canvas.getContext('2d').clearRect(0, 0, next_canvas.width, next_canvas.height);
			next_canvas.getContext('2d').drawImage(slow_canvas, 0, 0);
			
			// slow canvas display new page
			slow_canvas.width = prev_canvas.width;
			slow_canvas.height = prev_canvas.height;
			
			function whenPrevCanvasReady() {
				if(prev_canvas_ready) {
					slow_canvas.getContext('2d').clearRect(0, 0, slow_canvas.width, slow_canvas.height);
					slow_canvas.getContext('2d').drawImage(prev_canvas, 0, 0);
			
					// move canvas
					move_canvas.style.zIndex = 99;
					move_canvas.classList.add("transitionPageOut");
					move_canvas.style.left = "+100%";
			
					// render new prev page
					prev_canvas_ready = false;
			
					afterRendering();
				} else setTimeout( whenPrevCanvasReady, 20 );
			}
			whenPrevCanvasReady();
		}
		// bigger jump - no animation - reset cache
		else {
			renderPage(pageNumber, -1, "slow-canvas", function(){ afterRendering(); ignore_page_turning = false; }, renderFailCallback);
			//TODO: two page jump would preserve one page of cache actually
			prev_canvas_ready = false;
			next_canvas_ready = false;
		}
	}
}
function afterRendering() {
	// finalize stuff
	centerCanvas();
	
	// Communicate with QML
	if(first_render) {
		first_render = false;
		console.log("Ready");
	}
	console.log("status_requested");
	
	// update cache
	if(!prev_canvas_ready)
		renderPage(pageNumber-1, -1, "prev-cache-canvas", function(){ prev_canvas_ready = true; }, renderFailCallback);
	if(!next_canvas_ready)
		renderPage(pageNumber+1, -1, "next-cache-canvas", function(){ next_canvas_ready = true; }, renderFailCallback);
}

function centerCanvas(){
	var slow_canvas = document.getElementById("slow-canvas");
	var move_canvas = document.getElementById("move-canvas");
	var next_canvas = document.getElementById("next-cache-canvas");
	var prev_canvas = document.getElementById("prev-cache-canvas");
	if(window.innerWidth / window.innerHeight < book_aspect_ratio) {
		slow_canvas.style.top = "50%";
		slow_canvas.style.transform = "translateY(-50%)";
		move_canvas.style.top = "50%";
		move_canvas.style.transform = "translateY(-50%)";
		next_canvas.style.top = "50%";
		next_canvas.style.transform = "translateY(-50%)";
		prev_canvas.style.top = "50%";
		prev_canvas.style.transform = "translateY(-50%)";
	} else {
		slow_canvas.style.top = "0px";
		slow_canvas.style.transform = "translateY(-0px)";
		move_canvas.style.top = "0px";
		move_canvas.style.transform = "translateY(-0px)";
		next_canvas.style.top = "0px";
		next_canvas.style.transform = "translateY(-0px)";
		prev_canvas.style.top = "0px";
		prev_canvas.style.transform = "translateY(-0px)";
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
function renderFailCallback(reason) { console.log("page rendering failed: " + reason); }

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
	ignore_page_turning = false;
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
			moveToPage(pageNumber, true);
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
		moveToPage(pageNumber, true);
}
