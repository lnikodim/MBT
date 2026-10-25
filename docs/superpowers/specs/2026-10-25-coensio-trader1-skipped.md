# CoensioTrader1V06 (mql5.com 2026): not run (DLL and external-server calls)

Date: 2026-10-25. User: "https://www.mql5.com/en/code/2026". Decision: the user chose "Skip it".

**The EA:** "CoensioTrader1V06" (coensio, published 2014-08-01).
- **Files:** `coensiotrader1v06.mq5` (MD5 7e641a3a…, 1,029 lines) and `coensiotrader1v06.mqh` (MD5 14cf2f2c…, 400
  lines).
- **The strategy:** multi-currency on a timer: a daily DEMA trend (three daily DEMA values in a row), a Bollinger band
  re-entry and a swing pattern, with a trailing stop.

**Why it was not run:**
- **DLL:** it imports `wininet.dll` (`InternetOpenW`, `InternetOpenUrlW`, `HttpQueryInfoW`).
- **Start-up:** `OnInit` returns failure unless DLL imports are allowed.
- **Kill switch:** every start, in the tester too, it reads `http://www.coensio.com/sts/<EA name>.msg`. If the server
  says "disabled" or cannot be reached, the EA refuses to start.
- **Data sent out:**
  - live, it reports each installation to the server;
  - after an optimisation, it uploads the top 25 passes' statistics.
- **Risk:** running it means enabling DLLs and sending requests to a 2014 domain whose current owner is unknown. If the
  server is gone, it cannot start at all.
- **Not tested:** a copy with only the network code removed was offered and not chosen.
- **Not installed:** nothing was added to `mql5/`, the profiles or MT5.
