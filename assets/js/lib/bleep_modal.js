export default class BleepModal {
  #bleep_init_button;
  #bleep_init_modal;
  #bleep;

  constructor(bleep) {
    this.#bleep_init_button = document.getElementById("bleep-init-button");
    this.#bleep_init_modal = document.getElementById("bleep-init-modal");
    this.#bleep = bleep;

    this.#bleep_init_button.addEventListener("click", this.#bleep_modal_clicked.bind(this));
    this.#bleep_init_modal.addEventListener("click", this.#bleep_modal_clicked.bind(this));
    document.addEventListener("keydown", this.#bleep_modal_keydown.bind(this));
  }

  #bleep_modal_keydown(e) {
    if (
      e.key === "Enter" ||
      e.code === "Enter" ||
      e.key === " " ||
      e.code === "Space"
    ) {
      // Your code to handle the Enter key press goes here
      this.#bleep_modal_clicked(e);
      console.log("Enter key pressed");
    }
  }

  #bleep_modal_clicked(e) {
    document.removeEventListener("keydown", this.#bleep_modal_keydown);
    this.#bleep_init_button.removeEventListener("click", this.#bleep_modal_clicked);
    this.#bleep_init_modal.removeEventListener("click", this.#bleep_modal_clicked);

    this.#bleep_init_modal.classList.add(
      "transition",
      "ease-out",
      "duration-1000",
      "opacity-100"
    );

    this.#bleep.idempotentInitAudio();
    this.#bleep_init_modal.classList.remove("opacity-100");
    this.#bleep_init_modal.classList.add("opacity-0");

    setTimeout(() => {
      this.#bleep_init_modal.style.display = "none";
    }, 1000);
  }
}
