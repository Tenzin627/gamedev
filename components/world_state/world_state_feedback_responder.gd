extends Node
class_name WorldStateFeedbackResponder

@export var binding_path: NodePath = NodePath("../WorldStateBinding")
@export var active_particles_path: NodePath = NodePath("")
@export var inactive_particles_path: NodePath = NodePath("")
@export var active_audio_path: NodePath = NodePath("")
@export var inactive_audio_path: NodePath = NodePath("")
@export var play_audio_on_change: bool = true

var _binding: WorldStateBindingComponent = null
var _has_applied_initial_state: bool = false

func _ready() -> void:
    _binding = get_node_or_null(binding_path) as WorldStateBindingComponent
    if _binding == null:
        return
    if not _binding.active_changed.is_connected(_on_active_changed):
        _binding.active_changed.connect(_on_active_changed)
    _apply_feedback(_binding.is_active(), false)
    _has_applied_initial_state = true

func _on_active_changed(active: bool) -> void:
    _apply_feedback(active, _has_applied_initial_state and play_audio_on_change)
    _has_applied_initial_state = true

func _apply_feedback(active: bool, allow_audio: bool) -> void:
    var active_particles: GPUParticles2D = _get_particles(active_particles_path)
    var inactive_particles: GPUParticles2D = _get_particles(inactive_particles_path)
    if active_particles != null:
        active_particles.emitting = active
    if inactive_particles != null:
        inactive_particles.emitting = not active
    if not allow_audio:
        return

    var player: AudioStreamPlayer2D = null
    if active:
        player = _get_audio_player(active_audio_path)
    else:
        player = _get_audio_player(inactive_audio_path)
    if player != null and player.stream != null:
        player.play()

func _get_particles(path: NodePath) -> GPUParticles2D:
    if path.is_empty():
        return null
    return get_node_or_null(path) as GPUParticles2D

func _get_audio_player(path: NodePath) -> AudioStreamPlayer2D:
    if path.is_empty():
        return null
    return get_node_or_null(path) as AudioStreamPlayer2D
