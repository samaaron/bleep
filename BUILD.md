# How to build Bleep

This article describes how to get a development version of Bleep running locally on your machine.

## Dependencies

Bleep is implemented on top of Elixir and only has one local dependency which is the Elixir language and runtime (BEAM). Instructions for installing the latest release of Elixir for your operating system can be found here:

https://elixir-lang.org/install.html

You can verify that you have Elixir correctly installed on your machine by starting up the interactive shell by running `iex --version` in your terminal/console. You should see something similar to:

```
> iex --version
IEx 1.15.4 (compiled with Erlang/OTP 26)
```

## Fetch Code

Once you have Elixir installed, you next need to grab a copy of the source code. This can be found here:

https://github.com/samaaron/bleep

Either download the latest zip or if you want to be able to easily keep up to date with future development clone via git (into a suitable directory on your system):

git clone https://github.com/samaaron/bleep

## Build the app

Next you need to fetch the Elixir dependencies, compile the code and build the assets. This is achieved using Elixir's build tool `mix`:

```
cd bleep
mix setup
```

## Start the app

You can now start the app in development mode and also open a live interactive shell to the running system with the following:

```
iex -S mix phx.server
```

Once this has started, you should be able to open a browser to `localhost:4000` to see the running app. You can also use the terminal/console to evaluate Elixir code directly in the running process and see live log output.

Have fun!