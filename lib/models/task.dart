import 'dart:convert';
import 'package:flutter/material.dart';

enum Priority { high, medium, low }

class Task {
  final int? id;
  final String title;
  final String description;
  final Priority priority;
  final bool isCompleted;
  final bool isDeleted; // 🔹 Для корзины
  final int? timerDuration;
  final DateTime createdAt;
  final DateTime? completedAt;

  Task({
    this.id,
    required this.title,
    this.description = '',
    this.priority = Priority.medium,
    this.isCompleted = false,
    this.isDeleted = false,
    this.timerDuration,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.index,
      'isCompleted': isCompleted ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
      'timerDuration': timerDuration,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      priority: Priority.values[map['priority']],
      isCompleted: map['isCompleted'] == 1,
      isDeleted: map['isDeleted'] == 1,
      timerDuration: map['timerDuration'],
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
    );
  }

  Task copyWith({
    int? id, String? title, String? description, Priority? priority,
    bool? isCompleted, bool? isDeleted, int? timerDuration,
    DateTime? createdAt, DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id, title: title ?? this.title, description: description ?? this.description,
      priority: priority ?? this.priority, isCompleted: isCompleted ?? this.isCompleted,
      isDeleted: isDeleted ?? this.isDeleted, timerDuration: timerDuration ?? this.timerDuration,
      createdAt: createdAt ?? this.createdAt, completedAt: completedAt ?? this.completedAt,
    );
  }

  String toJson() => json.encode(toMap());
  factory Task.fromJson(String source) => Task.fromMap(json.decode(source));

  Color getPriorityColor() {
    switch (priority) {
      case Priority.high: return Colors.red;
      case Priority.medium: return Colors.orange;
      case Priority.low: return Colors.green;
    }
  }

  String getPriorityName() {
    switch (priority) {
      case Priority.high: return 'Высокий';
      case Priority.medium: return 'Средний';
      case Priority.low: return 'Низкий';
    }
  }
}