defmodule Ev3.Actuator do
	@moduledoc "An actuator that translates intents into commands sent to motors"

	require Logger
	alias Ev3.LegoMotor
	alias Ev3.Script
	alias Ev3.MotorSpec
	alias Ev3.LEDSpec
	alias Ev3.LegoLED
	alias Ev3.Device
	alias Ev3.CNS
	import Ev3.Utils

	@max_intent_age 1000 # intents older than 1 sec are dropped


	@doc "Start an actuator from a configuration"
	def start_link(actuator_config) do
		Logger.info("Starting #{__MODULE__} #{actuator_config.name}")
		state = if actuator_config.type == :motor do
							%{actuator_config: actuator_config,
								devices: find_motors(actuator_config.specs)}
						else
							%{actuator_config: actuator_config,
								devices: find_leds(actuator_config.specs)}
						end
		Agent.start_link(fn() -> state end, [name: actuator_config.name])
	end

	def realize_intent(name, intent) do
		Agent.update(
			name,
			fn(state) ->
				if intent_fresh?(intent) do
					state.actuator_config.activations
					|> Enum.filter_map(
						fn(activation) -> activation.intent == intent.about end,
						fn(activation) -> activation.action end)
					|> Enum.each( # execute activated actions sequentially
						fn(action) ->
							script = action.(intent, state.devices)
							Script.execute(state.actuator_config.type, script)
							CNS.notify_realized(intent) # This will have the intent stored in memory. Unrealized intents are not retained in memory.
						end)
				else
					IO.puts("STALE: Actuator #{name} not realizing intent #{intent.about} #{inspect intent.value}")
				end
				state
			end,
			30_000
		)
	end

	### Private

	defp intent_fresh?(intent) do
		(now() - intent.since) < @max_intent_age
	end

	defp find_motors(motor_specs) do
		all_motors = LegoMotor.motors()
		found = Enum.reduce(
			motor_specs,
			%{},
			fn(motor_spec, acc) ->
				motor = Enum.find(all_motors,
													&(MotorSpec.matches?(motor_spec, &1)))
				if motor == nil do
					Logger.warn("Motor not found matching #{inspect motor_spec} in #{inspect all_motors}")
				end
				Map.put(acc, motor_spec.name, motor)
			end)
		found
	end

	defp find_leds(led_specs) do
		all_leds = LegoLED.leds()
		found = Enum.reduce(
			led_specs,
			%{},
			fn(led_spec, acc) ->
				led = Enum.find(all_leds,
													&(LEDSpec.matches?(led_spec, &1)))
				if led == nil do
					Logger.warn("LED not found matching #{inspect led_spec} in #{inspect all_leds}")
				end
				Map.put(acc, led_spec.name, led)
			end)
		found
	end

end
