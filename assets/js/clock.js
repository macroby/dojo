// Manages the clock ui for a single player.
// Does not contain chess timekeeping logic.
// Only updates the clock ui by calling the decrement_by_tenth() method,
// or the increment_by_setting() method.
// Timekeeping happens outside the class in room.js file.
class Clock {
    constructor(element, time_control, inc) {
      this.element = element;
      this.time_control = time_control;
      this.inc = inc;
      this.minutes = time_control;
      this.seconds = 0;
      this.tenths = 0;
  
      this.element.innerHTML = this.time_as_string();
    }
  
    time_as_string() {
      let minutes = this.minutes;
      let seconds = this.seconds;
      let tenths = this.tenths;
  
      if (minutes < 10) {
        minutes = "0" + minutes;
      }
      if (seconds < 10) {
        seconds = "0" + seconds;
      }
  
      return minutes + ":" + seconds + "." + tenths;
    }
  
    decrement_by_tenth() {
      if (this.tenths === 0 && this.seconds > 0) {
        this.tenths = 9;
        this.seconds = this.seconds - 1;
      } else if (this.tenths > 0) {
        this.tenths = this.tenths - 1;
      } else if (this.seconds === 0 && this.tenths ==0 && this.minutes > 0) {
        this.seconds = 59;
        this.tenths = 9;
        this.minutes = this.minutes - 1;
      } else if (this.seconds === 0 && this.minutes === 0 && this.tenths === 0) {
      }
      this.element.innerHTML = this.time_as_string();
    }
  
    increment_by_setting() {
      this.seconds = this.seconds + this.inc;
      if (this.seconds >= 60) {
        this.minutes = this.minutes + 1;
        this.seconds = this.seconds - 60;
      }
      this.element.innerHTML = this.time_as_string();
    }
  }

export default Clock;
  