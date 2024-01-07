const bleep_init_button = document.getElementById("bleep-init-button");
const bleep_init_modal = document.getElementById("bleep-init-modal");

function bleep_modal_keydown(e) {
  if (
    e.key === "Enter" ||
    e.code === "Enter" ||
    e.key === " " ||
    e.code === "Space"
  ) {
    // Your code to handle the Enter key press goes here
    bleep_modal_clicked(e);
    console.log("Enter key pressed");
  }
}

function bleep_modal_clicked(e) {
  document.removeEventListener("keydown", bleep_modal_keydown);
  bleep_init_button.removeEventListener("click", bleep_modal_clicked);
  bleep_init_modal.removeEventListener("click", bleep_modal_clicked);

  bleep_init_modal.classList.add(
    "transition",
    "ease-out",
    "duration-1000",
    "opacity-100"
  );

  window.bleep.idempotentInit();
  bleep_init_modal.classList.remove("opacity-100");
  bleep_init_modal.classList.add("opacity-0");

  setTimeout(() => {
    bleep_init_modal.style.display = "none";
  }, 1000);
}

bleep_init_button.addEventListener("click", bleep_modal_clicked);
bleep_init_modal.addEventListener("click", bleep_modal_clicked);
document.addEventListener("keydown", bleep_modal_keydown);
