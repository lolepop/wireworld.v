module wireworld

import gg
import gx

const (
	connection_char = "#"
	electron_head_char = "@"
	electorn_tail_char = "-"
	empty_char = "."
)

fn swap<T>(mut a &T, mut b &T)
{
	unsafe
	{
		c := *a
		*a = *b
		*b = c
	}
}

[inline]
fn (w Wireworld) ctoi(x int, y int, ox int, oy int) int
{
	ny := y + oy
	nx := x + ox

	if ny < 0 || ny >= w.y_resolution || nx < 0 || nx >= w.x_resolution
	{
		return -1
	}

	return ny * w.x_resolution + nx
}

pub struct Wireworld
{
	electron_head_colour gx.Color
	electron_tail_colour gx.Color
	connection_colour gx.Color
	x_resolution int
	y_resolution int
mut:
	curr_map []u8
	next_map []u8
}

pub struct WireworldOptions
{
	map []u8 [required]
	x_resolution int [required]
	y_resolution int [required]
	electron_head_colour gx.Color = gx.blue
	electron_tail_colour gx.Color = gx.red
	connection_colour gx.Color = gx.yellow
}

pub fn create_world(options WireworldOptions) &Wireworld
{
	return &Wireworld{
		curr_map: options.map
		next_map: options.map.clone()
		x_resolution: options.x_resolution
		y_resolution: options.y_resolution
		electron_head_colour: options.electron_head_colour
		electron_tail_colour: options.electron_tail_colour
		connection_colour: options.connection_colour
	}
}

[direct_array_access]
pub fn (this Wireworld) draw(gg &gg.Context, res_scale int, should_draw_grid bool)
{
	pixels := this.curr_map

	for y in 0..this.y_resolution
	{
		for x in 0..this.x_resolution
		{
			p := pixels[this.ctoi(x, y, 0, 0)]
			connection := p & 1

			if connection == 1
			{
				c := match p {
					0b11 { this.electron_head_colour }
					0b101 { this.electron_tail_colour }
					else { this.connection_colour }
				}
				gg.draw_square(x * res_scale, y * res_scale, res_scale, c)
			}

		}
	}

	if should_draw_grid
	{
		for y in 0..this.y_resolution
		{
			gg.draw_line(0, y * res_scale, this.x_resolution * res_scale, y * res_scale, gx.gray)
		}
		for x in 0..this.x_resolution
		{
			gg.draw_line(x * res_scale, 0, x * res_scale, this.y_resolution * res_scale, gx.gray)
		}
	}

}

[direct_array_access]
pub fn (mut this Wireworld) tick()
{
	pixels := this.curr_map
	mut next := this.next_map
	
	mut con_count := map[int]int{}
	for y in 0..this.y_resolution
	{
		for x in 0..this.x_resolution
		{
			// clear any artifacts
			next[this.ctoi(x, y, 0, 0)] &= 1

			p := pixels[this.ctoi(x, y, 0, 0)]
			if p <= 1 { continue }

			// head
			if p == 0b11
			{
				neighbour := [
					this.ctoi(x, y, -1, -1),
					this.ctoi(x, y, 0, -1),
					this.ctoi(x, y, 1, -1),
					this.ctoi(x, y, -1, 0),
					this.ctoi(x, y, 1, 0),
					this.ctoi(x, y, -1, 1),
					this.ctoi(x, y, 0, 1),
					this.ctoi(x, y, 1, 1),
				]

				// add all moore neighbours that are exclusively conductors
				for i in neighbour
				{
					if i > 0 && pixels[i] == 1
					{
						con_count[i]++
					}
				}

				next[this.ctoi(x, y, 0, 0)] = p ^ 0b110
			}
			else
			{
				// tail
				next[this.ctoi(x, y, 0, 0)] = 1
			}


		}
	}
	
	// only create new electron heads for valid cells (exactly surrounded by 1 or 2 heads)
	for k in con_count.keys()
	{
		v := con_count[k]
		if v >= 1 && v <= 2
		{
			next[k] = pixels[k] | 0b10
		}
	}

	swap<[]u8>(mut this.curr_map, mut this.next_map)
}

pub fn (mut this Wireworld) toggle_cell(x int, y int)
{
	p := this.ctoi(x, y, 0, 0)
	this.curr_map[p] = this.curr_map[p] & 1 ^ 1
	this.next_map[p] = this.curr_map[p]
}

pub fn (mut this Wireworld) add_electron(x int, y int)
{
	p := this.ctoi(x, y, 0, 0)
	a := this.curr_map[p]
	if a & 1 == 1
	{
		this.curr_map[p] = match true {
			a == 1 { 0b11 }
			a & 0b10 != 0 { 0b101 }
			else { 1 }
		}
	}
}

pub fn (mut this Wireworld) clear()
{
	this.curr_map = this.curr_map.map(fn (a u8) u8 { return 0 })
	this.next_map = this.curr_map.clone()
}

pub fn (this Wireworld) serialise_map() string
{
	mut out := ""

	for y in 0..this.y_resolution
	{
		for x in 0..this.x_resolution
		{
			out += match this.curr_map[this.ctoi(x, y, 0, 0)] {
				1 { connection_char }
				0b11 { electron_head_char }
				0b101 { electorn_tail_char }
				else { empty_char }
			}
		}
		out += "\n"
	}
	dump(out)
	return out[0..out.len-1]
}

pub fn deserialise_map(m string) (int, int, []u8)
{
	mut out := []u8{}

	mut n := 0
	mut i := 0
	for v in m
	{
		c := v.ascii_str()

		match c {
			connection_char, electron_head_char, electorn_tail_char, empty_char {
				out << match c {
					connection_char { 1 }
					electron_head_char { 0b11 }
					electorn_tail_char { 0b101 }
					empty_char { 0 }
					else { panic("wtf") }
				}
				i++
			}
			"\n" { n++ }
			else {}
		}

	}

	return i / (n + 1), n + 1, out
}
