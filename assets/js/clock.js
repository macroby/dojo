// Manages the clock ui for a single player.
// Does not contain chess timekeeping logic.
// Only updates the clock ui by calling the decrement_by_tenth() method,
// or the increment_by_setting() method.
// Timekeeping happens outside the class in room.js file.
class Clock {
    constructor(element, init_time, inc) {
      this.element = element;
      this.inc = inc;
      this.milli = init_time;
  
      this.element.innerHTML = this.time_as_string();
    }
  
    time_as_string() {
      let minutes = Math.floor(this.milli / 1000 / 60);
      let seconds = Math.floor(this.milli / 1000) % 60;
      let tenths = Math.floor((this.milli % 1000) / 100);

      if (minutes === 0) {
        if (seconds < 10) {
          seconds = "0" + seconds;
        }
    
        return seconds + "." + tenths;
      } else {
        if (minutes < 10) {
          minutes = "0" + minutes;
        }
        if (seconds < 10) {
          seconds = "0" + seconds;
        }
    
        return minutes + ":" + seconds;
      }
    }
  
    decrement_time(t) {
      this.milli -= t;

      if (this.milli < 0) {
        this.milli = 0;
      }

      this.element.innerHTML = this.time_as_string();
    }

    set_time(t) {
      this.milli = t;
      this.element.innerHTML = this.time_as_string();
    }
  
    // Increment the clock by the increment setting.
    // Not used rightnow because the increment is handled in the server.
    // And the server sends the new time to the client to update the clock.
    increment_by_setting() {
      this.milli += this.inc*1000;
      this.element.innerHTML = this.time_as_string();
    }
  }

export default Clock;
  