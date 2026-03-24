# accounts/views.py
from django.contrib.auth import authenticate
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from .models import Follow, User
from .serializers import RegisterSerializer, LoginSerializer, UserSerializer, get_tokens
from .recommendations import adamic_adar_recommendations


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


# ── Follow / Unfollow ──────────────────────────────────────────────────────────
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def follow_toggle(request, user_id):
    """POST → follow if not already following, unfollow if following."""
    if request.user.pk == user_id:
        return Response({'detail': 'Cannot follow yourself.'}, status=status.HTTP_400_BAD_REQUEST)
    try:
        target = User.objects.get(pk=user_id)
    except User.DoesNotExist:
        return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

    follow_qs = Follow.objects.filter(follower=request.user, following=target)
    if follow_qs.exists():
        follow_qs.delete()
        following = False
    else:
        Follow.objects.create(follower=request.user, following=target)
        following = True

    return Response({
        'is_following':    following,
        'followers_count': target.followers_count,
    })


# ── Followers / Following lists ────────────────────────────────────────────────
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def followers_list(request, user_id):
    """Returns the list of users that follow <user_id>."""
    try:
        target = User.objects.get(pk=user_id)
    except User.DoesNotExist:
        return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

    users = User.objects.filter(following__following=target)
    return Response(UserSerializer(users, many=True, context={'request': request}).data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def following_list(request, user_id):
    """Returns the list of users that <user_id> follows."""
    try:
        target = User.objects.get(pk=user_id)
    except User.DoesNotExist:
        return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

    users = User.objects.filter(followers__follower=target)
    return Response(UserSerializer(users, many=True, context={'request': request}).data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def recommendations(request):
    """
    Returns a list of recommended users to follow based on the Adamic-Adar Index.
    Excludes users the requesting user is already following, and the user themselves.
    """
    recommended_users = adamic_adar_recommendations(request.user, limit=10)
    serializer = UserSerializer(recommended_users, many=True, context={'request': request})
    return Response(serializer.data, status=status.HTTP_200_OK)
