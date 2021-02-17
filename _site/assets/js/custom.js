function myFunction() {
    var x = document.getElementById("navigation");
    if (x.className === "") {
      x.className += "responsive";
    } else {
      x.className = "";
    }
  }