# feed/views.py
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Post, Like, Comment
from .serializers import PostSerializer, CommentSerializer, CreatePostSerializer


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser, JSONParser])
def posts(request):
    if request.method == 'GET':
        qs  = Post.objects.select_related('author').prefetch_related('likes', 'comments')
        ser = PostSerializer(qs, many=True, context={'request': request})
        return Response(ser.data)

    # POST — create post (multipart so image can be uploaded)
    ser = CreatePostSerializer(data=request.data, context={'request': request})
    if ser.is_valid():
        post = ser.save()
        return Response(
            PostSerializer(post, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
        )
    return Response(ser.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def toggle_like(request, post_id):
    try:
        post = Post.objects.get(pk=post_id)
    except Post.DoesNotExist:
        return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

    like, created = Like.objects.get_or_create(user=request.user, post=post)
    if not created:
        like.delete()

    return Response({
        'liked':       created,
        'likes_count': post.likes.count(),
    })


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def comments(request, post_id):
    try:
        post = Post.objects.get(pk=post_id)
    except Post.DoesNotExist:
        return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        ser = CommentSerializer(post.comments.select_related('author'), many=True)
        return Response(ser.data)

    # POST — add comment
    ser = CommentSerializer(data=request.data)
    if ser.is_valid():
        ser.save(post=post, author=request.user)
        return Response(ser.data, status=status.HTTP_201_CREATED)
    return Response(ser.errors, status=status.HTTP_400_BAD_REQUEST)
