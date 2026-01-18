<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
ul {
  margin: 0;
  padding: 0;
}

html {
  margin: 10px;
  font-family: Arial, Helvetica, sans-serif;
}

.release {
  border-top: 2px solid lightgray;
  margin-bottom: 20px;
}

.release-head {
  font-size: 150%;
  margin-bottom: 10px;
  margin-top: 10px;
}

.dep {
  margin-left: 10px;
  margin-bottom: 10px;
}

.pr {
  margin-left: 10px;
  margin-bottom: 10px;
}

.pr-head {
  font-size: 120%;
  margin-bottom: 10px;
}

.commit {
  margin-left: 10px;
  margin-bottom: 20px;
}

.commit:first-child {
  margin-top: 15px;
}

.commit-head {
  margin-bottom: 10px;
}

.msg {
  margin-top: 10px;
  margin-left: 26px;
}

.caret {
  cursor: pointer;
  -webkit-user-select: none; /* Safari 3.1+ */
  -moz-user-select: none; /* Firefox 2+ */
  -ms-user-select: none; /* IE 10+ */
  user-select: none;
}

.caret::before {
  content: "\229E";
  font-size: 14pt;
  color: #aaa;
  display: inline-block;
  vertical-align: bottom;
  text-align: bottom;
  margin-right: 6px;
  width: 20px;
}

.caret-down::before {
  content: "\229F";
  font-size: 14pt;
  color: #aaa;
  display: inline-block;
  vertical-align: bottom;
  text-align: bottom;
  margin-right: 6px;
  width: 20px;

  /*
  -ms-transform: rotate(90deg); /* IE 9
  -webkit-transform: rotate(90deg); /* Safari
  transform: rotate(90deg);
  */
}

.nested {
  display: none;
}

.active {
  display: block;
}
</style>
<script>
</script>
</head>
<body>

<h1>Changelog</h1>
<p>The latest release was 2026-01-18.</p>

<!-- ### VERSIO BEGIN CONTENT ### -->
<!-- ### VERSIO CONTENT 2026-01-18 ### -->
<div class="release">
  <div class="release-head"><span class="caret caret-down"></span>Release 1.2.0 : 2026-01-18</div>
  <div class="nested active">
    
    
    <div class="pr">
      <div class="pr-head"><span class="caret"></span>Commits (none)</div>
      <div class="nested">
        
        <div class="commit">
          <div class="commit-head"><span class="caret"></span>Commit <a href="https://github.com/davidcharbonnier/alacarte/commit/9b297aaf60c49bd0b73cdd054643e0c60b04b6f4">9b297aa</a> (none): chore(docs): deduplicate docs and update navigation</div>
          <pre class="msg nested">chore(docs): deduplicate docs and update navigation</pre>
        </div>
        
      </div>
    </div>
    
  </div>
</div>
<!-- ### VERSIO CONTENT 2025-12-02 ### -->
<div class="release">
  <div class="release-head"><span class="caret caret-down"></span>Release 1.2.0 : 2025-12-02</div>
  <div class="nested active">
    
    
    <div class="pr">
      <div class="pr-head"><span class="caret"></span>Commits (minor)</div>
      <div class="nested">
        
        <div class="commit">
          <div class="commit-head"><span class="caret"></span>Commit <a href="https://github.com/davidcharbonnier/alacarte/commit/96230286b71b07e7641522fbbd4b26e6f4e0e9c0">9623028</a> (minor): feat(client): Fix name of the platform</div>
          <pre class="msg nested">feat(client): Fix name of the platform</pre>
        </div>
        
        <div class="commit">
          <div class="commit-head"><span class="caret"></span>Commit <a href="https://github.com/davidcharbonnier/alacarte/commit/5da249eefe1497fa516b1e666020a1588c2ff69d">5da249e</a> (minor): feat(client): Support alphabetical sorting of accentuated strings</div>
          <pre class="msg nested">feat(client): Support alphabetical sorting of accentuated strings</pre>
        </div>
        
        <div class="commit">
          <div class="commit-head"><span class="caret"></span>Commit <a href="https://github.com/davidcharbonnier/alacarte/commit/6341a9d3ccf83da230a134a6ca5eac1fc422d88e">6341a9d</a> (patch): fix(client): Update helper text for tasting notes for coffee item</div>
          <pre class="msg nested">fix(client): Update helper text for tasting notes for coffee item</pre>
        </div>
        
      </div>
    </div>
    
  </div>
</div>
<!-- ### VERSIO CONTENT 2025-12-01 ### -->
<div class="release">
  <div class="release-head"><span class="caret caret-down"></span>Release 1.1.0 : 2025-12-01</div>
  <div class="nested active">
    
    
    <div class="pr">
      <div class="pr-head"><span class="caret"></span>Commits (minor)</div>
      <div class="nested">
        
        <div class="commit">
          <div class="commit-head"><span class="caret"></span>Commit <a href="https://github.com/davidcharbonnier/alacarte/commit/c5bd4e3d371abff65b7a697c750f23c2063f6563">c5bd4e3</a> (patch): fix(client): Remove unwanted files</div>
          <pre class="msg nested">fix(client): Remove unwanted files</pre>
        </div>
        
        <div class="commit">
          <div class="commit-head"><span class="caret"></span>Commit <a href="https://github.com/davidcharbonnier/alacarte/commit/077064c6ac5fb506f1661e9c1b3ab3956bac85af">077064c</a> (minor): feat(client): Upgrade riverpod dependency</div>
          <pre class="msg nested">feat(client): Upgrade riverpod dependency</pre>
        </div>
        
        <div class="commit">
          <div class="commit-head"><span class="caret"></span>Commit <a href="https://github.com/davidcharbonnier/alacarte/commit/8119938bb9f998f20a73eedc39869c3ddd36df78">8119938</a> (minor): feat(client): Upgrade google_sign_in dependency</div>
          <pre class="msg nested">feat(client): Upgrade google_sign_in dependency</pre>
        </div>
        
        <div class="commit">
          <div class="commit-head"><span class="caret"></span>Commit <a href="https://github.com/davidcharbonnier/alacarte/commit/1ff5c0be343b0aa554ec3a03d88e401ba11c1506">1ff5c0b</a> (minor): feat(client): Upgrade dependencies</div>
          <pre class="msg nested">feat(client): Upgrade dependencies</pre>
        </div>
        
        <div class="commit">
          <div class="commit-head"><span class="caret"></span>Commit <a href="https://github.com/davidcharbonnier/alacarte/commit/d19c8a122e434077af76604af1433b78c89b101a">d19c8a1</a> (patch): fix(client): Clearing most of linting issues and dead code</div>
          <pre class="msg nested">fix(client): Clearing most of linting issues and dead code</pre>
        </div>
        
      </div>
    </div>
    
  </div>
</div>

<!-- ### VERSIO END CONTENT ### -->

<script>
var toggler = document.getElementsByClassName("caret");
var i;

for (i = 0; i < toggler.length; i++) {
  toggler[i].addEventListener("click", function() {
    this.parentElement.parentElement.querySelector(".nested").classList.toggle("active");
    this.classList.toggle("caret-down");
  });
}
</script>

</body>
</html>
