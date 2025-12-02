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
<p>The latest release was 2025-12-02.</p>

<!-- ### VERSIO BEGIN CONTENT ### -->
<!-- ### VERSIO CONTENT 2025-12-02 ### -->
<div class="release">
  <div class="release-head"><span class="caret caret-down"></span>Release 1.1.0 : 2025-12-02</div>
  <div class="nested active">
    
    
    <div class="pr">
      <div class="pr-head"><span class="caret"></span>Commits (minor)</div>
      <div class="nested">
        
        <div class="commit">
          <div class="commit-head"><span class="caret"></span>Commit <a href="https://github.com/davidcharbonnier/alacarte/commit/7166b315216a17a7a60901b3ef622282ea041aaf">7166b31</a> (minor): feat(api): Fix name of the platform</div>
          <pre class="msg nested">feat(api): Fix name of the platform</pre>
        </div>
        
        <div class="commit">
          <div class="commit-head"><span class="caret"></span>Commit <a href="https://github.com/davidcharbonnier/alacarte/commit/b20ce3d97c821cf33d6b02e86c57ffe93462b16c">b20ce3d</a> (patch): fix(api): Add json tags in each model to avoid issues when saving objects</div>
          <pre class="msg nested">fix(api): Add json tags in each model to avoid issues when saving
objects</pre>
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
