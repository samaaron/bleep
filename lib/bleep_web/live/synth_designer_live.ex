defmodule BleepWeb.SynthDesignerLive do
  use BleepWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Bleep Synth Designer")
      |> assign(:synth_builder, true)
      |> assign(:root_css, "/sheet.css")

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <p>
      <button class="orangebutton" id="start-button">Start</button>
      <button class="greybutton" id="load-button">Load</button>
      <button class="greybutton" id="save-button">Save</button>
      <button class="greybutton" id="save-as-button">Save As</button>
      <button class="greybutton" id="clip-button">Copy Params</button>
      <button class="greybutton" id="docs-button">Copy Docs</button>
      <button class="midibutton" id="midi-learn-button">MIDI Learn</button>
      <span id="midi-label">&nbsp;Midi input:&nbsp;</span><select class="dropdown" id="midi-input"></select>
      <span id="fx-label">&nbsp;Effect:&nbsp;</span><select class="dropdown" id="fx-select"></select>
      <span id="preset-label">&nbsp;Preset:&nbsp;</span><select class="dropdown" id="preset-select"></select>
      <span id="dot" style="color:#e6983f; opacity:0;">&nbsp;&#x25C9;</span>
    </p>

    <p>
      <div id="file-label">Current file: none</div>
      <div class="monitor" id="monitor">idle</div>
    </p>

    <table border="0px" padding="0px">
      <tr>
        <td>
          <canvas id="scope-canvas" class="bleep-canvas" width="520" height="40">
            Your browser does not support the HTML5 canvas tag.
          </canvas>
        </td>
        <td>
          <div id="rms-label" class="monitor">
            &nbsp;&nbsp;RMS=0.0000, Peak RMS=0.0000
          </div>
        </td>
      </tr>
    </table>

    <div id="bleep-synth-designer-editor" class="body-container" phx-update="ignore">
      <div class="column fixed-width">
        <textarea class="textarea" rows="29" id="synth-spec"></textarea><br />
        <textarea readonly class="textarea" rows="4" id="parse-errors"></textarea>
      </div>
      <div class="column content-width">
        <table>
          <tr>
            <td valign="top">
              <div class="slider-container">
                <input
                  class="slider"
                  type="range"
                  id="slider-pitch"
                  min="24"
                  max="108"
                  value="60"
                  step="1"
                />
                <label id="label-pitch" for="slider-pitch">pitch [C4]</label>
              </div>
              <div class="slider-container">
                <input
                  class="slider"
                  type="range"
                  id="slider-level"
                  min="0"
                  max="1"
                  value="1"
                  step="0.01"
                />
                <label id="label-level" for="slider-level">level [1]</label>
              </div>

              <div class="slider-container">
                <input
                  class="slider"
                  type="range"
                  id="slider-wetLevel"
                  min="0"
                  max="1"
                  value="0.5"
                  step="0.01"
                />
                <label id="label-wetLevel" for="slider-wetLevel">wetLevel [1]</label>
              </div>

              <button class="playbutton" id="play-button">Play</button>
              <table>
                <tr>
                  <td valign="top">
                    <div id="container1"></div>
                  </td>
                  <td valign="top">
                    <div id="container2"></div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </div>
    </div>

    <div class="column remaining-width">
      <div id="mermaid-graph" class="mermaid-container"></div>
    </div>
    """
  end
end
