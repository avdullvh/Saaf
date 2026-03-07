# accounts/views.py
from django.contrib.auth import authenticate
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from .models import User
from .serializers import RegisterSerializer, LoginSerializer, UserSerializer, get_tokens


@api_view(['POST'])
@permission_classes([AllowAny])
def register(request):
    ser = RegisterSerializer(data=request.data)
    if ser.is_valid():
        user   = ser.save()
        tokens = get_tokens(user)
        return Response(
            {'user': UserSerializer(user, context={'request': request}).data, **tokens},
            status=status.HTTP_201_CREATED,
        )
    return Response(ser.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def login(request):
    ser = LoginSerializer(data=request.data)
    ser.is_valid(raise_exception=True)

    user = authenticate(
        request,
        username=ser.validated_data['email'],
        password=ser.validated_data['password'],
    )
    if user is None:
        return Response(
            {'detail': 'Invalid credentials.'},
            status=status.HTTP_401_UNAUTHORIZED,
        )
    tokens = get_tokens(user)
    return Response({'user': UserSerializer(user, context={'request': request}).data, **tokens})


# ── Profile views ──────────────────────────────────────────────────────────────
@api_view(['GET', 'PATCH'])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser, JSONParser])
def profile(request, user_id):
    try:
        user = User.objects.get(pk=user_id)
    except User.DoesNotExist:
        return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        return Response(UserSerializer(user, context={'request': request}).data)

    # PATCH — only own profile
    if request.user.pk != user.pk:
        return Response({'detail': 'Forbidden.'}, status=status.HTTP_403_FORBIDDEN)

    # Apply changes directly to the model instance then save once.
    # Bypasses the serializer write path to avoid ImageField being dropped.
    if 'full_name' in request.data:
        user.full_name = request.data['full_name'].strip()
    if 'bio' in request.data:
        user.bio = request.data['bio'].strip()
    if 'avatar' in request.FILES:
        user.avatar = request.FILES['avatar']

    user.save()
    return Response(UserSerializer(user, context={'request': request}).data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def profile_posts(request, user_id):
    from feed.models import Post
    from feed.serializers import PostSerializer
    posts = Post.objects.filter(author_id=user_id).order_by('-created_at')
    return Response(PostSerializer(posts, many=True, context={'request': request}).data)
