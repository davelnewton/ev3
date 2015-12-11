defmodule Ev3.Actuation do
	@moduledoc "Provides the configurations of all actuators to be activated"

	require Logger

	alias Ev3.ActuatorConfig
	alias Ev3.MotorSpec
	alias Ev3.LEDSpec
	alias Ev3.Activation
	alias Ev3.Script
	
	@doc "Give the configurations of all actuators to be activated"
  def actuator_configs() do
		[
				ActuatorConfig.new(name: :locomotion,
													 type: :motor,
													 specs: [  # to find and name motors from specs
														 %MotorSpec{name: :left_wheel, port: "outA"},
														 %MotorSpec{name: :right_wheel, port: "outB"}
													 ],
													 activations: [ # scripted actions to be taken upon receiving intents
														 %Activation{intent: :go_forward,
																				 action: going_forward()},
														 %Activation{intent: :go_backward,
																				 action: going_backward()},
														 %Activation{intent: :turn_right,
																				 action: turning_right()},
														 %Activation{intent: :turn_left,
																				 action: turning_left()},
														 %Activation{intent: :stop,
																				 action: stopping()}
													 ]),
				ActuatorConfig.new(name: :manipulation,
													 type: :motor,
													 specs: [
														 %MotorSpec{name: :mouth, port: "outC"}
													 ],
													 activations: [
														 %Activation{intent: :eat,
																				 action: eating()}
													 ]),
				ActuatorConfig.new(name: :leds,
													 type: :led,
													 specs: [
														 %LEDSpec{name: :lr, position: :left, color: :red},
														 %LEDSpec{name: :lg, position: :left, color: :green},
														 %LEDSpec{name: :rr, position: :right, color: :red},
														 %LEDSpec{name: :rg, position: :right, color: :green}
													 ],
													 activations: [
														 %Activation{intent: :green_lights,
																				 action: green_lights()},
														 %Activation{intent: :red_lights,
																				 action: red_lights()},
														 %Activation{intent: :all_lights,
																				 action: orange_lights()}
													 ])
		]
	end

	# locomotion

	defp going_forward() do
		fn(intent, motors) ->
			rps_speed = case intent.value.speed do
										:fast -> 3
										:slow -> 1
									end
			how_long = intent.value.time * 1000
			Script.new(:going_forward, motors)
			|> Script.add_step(:all, :set_speed, [:rps, rps_speed])
			|> Script.add_step(:all, :run_for, [how_long] )
			#			|> Script.add_wait(how_long)
		end
	end

	defp going_backward() do
		fn(intent, motors) ->
			rps_speed = case intent.value.speed do
										:fast -> 3
										:slow -> 1
									end
			how_long = intent.value.time * 1000
			Script.new(:going_backward, motors)
			|> Script.add_step(:all, :reset)
			|> Script.add_step(:all, :reverse_polarity)
			|> Script.add_step(:all, :set_speed, [:rps, rps_speed])
			|> Script.add_step(:all, :run_for, [how_long])
			|> Script.add_step(:all, :reverse_polarity)
		end
	end

	defp turning_right() do
		fn(_intent, motors) ->
			Script.new(:turning_right, motors)
			|> Script.add_step(:left_wheel, :set_speed, [:rps, 1])
			|> Script.add_step(:right_wheel, :set_speed, [:rps, -1])
			|> Script.add_step(:all, :run_for, [1000])
		end
  end

	defp turning_left() do
		fn(_intent, motors) ->
			Script.new(:turning_left, motors)
			|> Script.add_step(:right_wheel, :set_speed, [:rps, 1])
			|> Script.add_step(:left_wheel, :set_speed, [:rps, -1])
			|> Script.add_step(:all, :run_for, [1000])
		end
		# todo
  end

	defp stopping() do
		fn(_intent, motors) ->
			Script.new(:stopping, motors)
			|> Script.add_step(:all, :coast)
			|> Script.add_step(:all, :reset)
		end
  end

	# manipulation

	defp eating() do
		fn(_intent, motors) ->
			Script.new(:eating, motors)
			|> Script.add_step(:mouth, :set_speed, [:rps, 1])
			|> Script.add_step(:mouth, :run_for, [1000])
		end
	end

	# light

	defp green_lights() do
		fn(intent, leds) ->
			value = case intent.value do
								:on -> 255
								:off -> 0
							end
			Script.new(:green_lights, leds)
			|> Script.add_step(:lr, :set_brightness, [0])
			|> Script.add_step(:rr, :set_brightness, [0])
			|> Script.add_step(:lg, :set_brightness, [value])
			|> Script.add_step(:rg, :set_brightness, [value])
		end
	end
	
	defp red_lights() do
		fn(intent, leds) ->
			value = case intent.value do
								:on -> 255
								:off -> 0
							end
			Script.new(:red_lights, leds)
			|> Script.add_step(:lg, :set_brightness, [0])
			|> Script.add_step(:rg, :set_brightness, [0])
			|> Script.add_step(:lr, :set_brightness, [value])
			|> Script.add_step(:rr, :set_brightness, [value])
		end
	end
	
	defp orange_lights() do
		fn(intent, leds) ->
			value = case intent.value do
								:on -> 255
								:off -> 0
							end
			Script.new(:orange_lights, leds)
			|> Script.add_step(:all, :set_brightness, [value])
		end
	end
	
end
