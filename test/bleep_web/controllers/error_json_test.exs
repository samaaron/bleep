defmodule BleepWeb.ErrorJSONTest do
  use BleepWeb.ConnCase, async: true

  test "renders 404" do
    assert BleepWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert BleepWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
