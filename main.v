module main

import gg
import wireworld { Wireworld }
import time
import math

const (
	x_resolution = 16
	y_resolution = 16
	res_scale = 32
	update_rate = 10
	map = [
		u8(0),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,1,5,3,1,1,1,1,0,0,0,1,1,0,0,
		0,1,0,0,0,0,0,0,0,1,1,1,1,0,1,1,
		0,0,1,1,1,1,1,1,1,0,0,0,1,1,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	]
)

struct App
{
mut:
	should_update bool = true
	should_tick_once bool

	wireworld &Wireworld
	gg &gg.Context
}

fn render(mut app App)
{
	app.gg.begin()
	app.wireworld.draw(app.gg, res_scale)
	app.gg.end()

	if app.should_update || app.should_tick_once
	{
		app.should_tick_once = false
		app.wireworld.tick()
	}
	time.sleep(math.pow(update_rate, -1) * time.second)
}

[console]
fn main()
{
	mut app := &App {
		gg: 0
		wireworld: 0
	}
	app.gg = gg.new_context(
		window_title: "wireworld"
		width: (x_resolution * res_scale)
		height: (y_resolution * res_scale)
		resizable: false
		frame_fn: render
		user_data: app
	)

	mut wireworld := wireworld.create_world(wireworld.WireworldOptions{
		map: map
		x_resolution: x_resolution,
		y_resolution: y_resolution
	})
	
	app.wireworld = wireworld
	
	app.gg.run()
}
