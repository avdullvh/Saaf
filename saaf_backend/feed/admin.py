# feed/admin.py
from django.contrib import admin
from .models import Post, Like, Comment


@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    list_display  = ('id', 'author', 'predicted_type', 'confidence_score', 'likes_count', 'comments_count', 'created_at')
    list_filter   = ('predicted_type',)
    search_fields = ('author__email', 'author__full_name', 'caption')
    ordering      = ('-created_at',)


@admin.register(Like)
class LikeAdmin(admin.ModelAdmin):
    list_display = ('user', 'post')


@admin.register(Comment)
class CommentAdmin(admin.ModelAdmin):
    list_display  = ('author', 'post', 'body', 'created_at')
    search_fields = ('author__full_name', 'body')
    ordering      = ('-created_at',)
