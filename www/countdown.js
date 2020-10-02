/*==========================================================================
  Implement front page countdown
  ==========================================================================*/

//--- implement printf's %02d ----------------------------------------------

function n2(n)
{
  return n < 10 ? '0' + n : n;
}

//--- pluralize ------------------------------------------------------------

function pl(n, s)
{
  return n + ' ' + (n != 1 ? s + 's' : s);
}

//--- format date/time ----------------------------------------------------

function dt(t) {
  return (
    t.getFullYear() + '-' +
    n2(t.getMonth()+1) + '-' +
    n2(t.getDate()) + ' ' +
    n2(t.getHours()) + ':' +
    n2(t.getMinutes())
  );
}

//--- main ----------------------------------------------------------------

var
  start = new Date(1604188800*1000),
  end = new Date(1606780800*1000),
  min = 60000, hour = min*60, day = hour*24;

//--- interval handler ----------------------------------------------------

document.addEventListener("DOMContentLoaded", function(event) {

  var
    mode,
    counter = document.getElementById('counter'),
    when = document.getElementById('when'),
    interval_id;

  interval_id = setInterval(function() {

    var diff, days, hours, mins, secs;

    // before the tournament
    if(Date.now() < start) {
      diff = start - Date.now();
      if(mode != 'before') {
        document.querySelector('#countdown .initial').style.display = 'none';
        document.querySelector('#countdown .before').style.display = 'inline';
        document.querySelector('#countdown .counter').style.display = 'inline';
        // when.textContent = dt(start);
        when.textContent = "Nov 1 at midnight UTC"
        mode = 'before';
      }
    }

    // during the tournament
    else if(Date.now() < end) {
      diff = end - Date.now();
      if(mode != 'during') {
        if(mode != 'before') {
          document.querySelector('#countdown .counter').style.display = 'inline';
        }
        mode = 'during';
        document.querySelector('#countdown .before').style.display = 'none';
        document.querySelector('#countdown .during').style.display = 'inline';
        // when.textContent = dt(end);
        when.textContent = "Dec 1 at midnight UTC"
      }
    }

    // tournament is over, update the counter with text and unregister
    // the interval counter
    else {
      clearInterval(interval_id);
      document.querySelector('#countdown .counter').style.display = 'none';
      document.querySelector('#countdown .during').style.display = 'none';
      document.querySelector('#countdown .over').style.display = 'inline';
      return;
    }

    // update counter
    if(diff) {
      days = Math.floor(diff / day);
      diff = diff % day;

      hours = Math.floor(diff / hour);
      diff = diff % hour;

      mins = Math.floor(diff / min);
      diff = diff % min;

      secs = Math.floor(diff / 1000);
    }

    // update DOM

    if(days) {
    counter.textContent
      = pl(days, 'day') + ', ' + n2(hours) + ':' + n2(mins) + ':' + n2(secs);
    } else {
    counter.textContent
      = n2(hours) + ':' + n2(mins) + ':' + n2(secs);
    }

  }, 1000);

});

