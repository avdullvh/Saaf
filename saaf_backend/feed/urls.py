# feed/urls.py  — /api/posts/
from django.urls import path
from . import views

urlpatterns = [
    path('',                     views.posts,        name='posts-list'),
    path('<int:post_id>/like/',  views.toggle_like,  name='post-like'),
    path('<int:post_id>/comments/', views.comments,  name='post-comments'),
    path('<int:post_id>/',       views.delete_post,  name='post-delete'),
]
