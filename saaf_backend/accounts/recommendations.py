import math
from collections import defaultdict
from .models import User, Follow

def get_neighborhood(user_id):
    """
    Returns the set of user IDs that are in the neighborhood of user_id.
    Neighborhood = users that user_id follows U users that follow user_id.
    """
    following = Follow.objects.filter(follower_id=user_id).values_list('following_id', flat=True)
    followers = Follow.objects.filter(following_id=user_id).values_list('follower_id', flat=True)
    return set(following).union(set(followers))

def adamic_adar_recommendations(user, limit=10):
    """
    Implements the Adamic-Adar index for friend recommendation.
    AA(A, B) = sum(1 / log(|N(z)|)) for all z in N(A) intersection N(B)
    """
    user_neighbors = get_neighborhood(user.id)
    
    already_following = set(Follow.objects.filter(follower=user).values_list('following_id', flat=True))
    exclude_ids = already_following.union({user.id})
    
    # If the user has no connections at all, return random users they aren't following
    if not user_neighbors:
        return list(User.objects.exclude(id__in=exclude_ids).order_by('?')[:limit])
        
    scores = defaultdict(float)
    
    # Candidates are friends-of-friends
    candidates = set()
    for n_id in user_neighbors:
        n_neighbors = get_neighborhood(n_id)
        candidates.update(n_neighbors)
    
    # We only want to recommend people the user is NOT already following
    candidates = candidates - exclude_ids
    
    if not candidates:
        return list(User.objects.exclude(id__in=exclude_ids).order_by('?')[:limit])
        
    # Pre-calculate degrees for potential common neighbors to minimize DB queries
    common_neighbors_set = set()
    # Cache neighborhoods for candidates to avoid redundant DB queries
    candidate_neighborhoods = {}
    
    for c_id in candidates:
        c_neighbors = get_neighborhood(c_id)
        candidate_neighborhoods[c_id] = c_neighbors
        common = user_neighbors.intersection(c_neighbors)
        common_neighbors_set.update(common)
        
    degree_map = {z: len(get_neighborhood(z)) for z in common_neighbors_set}
    
    for c_id in candidates:
        common = user_neighbors.intersection(candidate_neighborhoods[c_id])
        
        score = 0.0
        for z in common:
            deg = degree_map.get(z, 0)
            if deg > 1: # log(1) is 0, avoid division by zero
                score += 1.0 / math.log(deg)
                
        scores[c_id] = score
        
    # Sort candidates by descending Adamic-Adar score
    sorted_candidates = sorted(scores.items(), key=lambda x: x[1], reverse=True)
    top_ids = [c[0] for c in sorted_candidates[:limit]]
    
    users = User.objects.filter(id__in=top_ids)
    user_dict = {u.id: u for u in users}
    
    # Preserve the sorted order
    result = [user_dict[uid] for uid in top_ids if uid in user_dict]
    
    # Backfill with random users if we didn't find enough recommendations through friends-of-friends
    if len(result) < limit:
        backfill_exclude = exclude_ids.union(set(top_ids))
        needed = limit - len(result)
        backfill_users = list(User.objects.exclude(id__in=backfill_exclude).order_by('?')[:needed])
        result.extend(backfill_users)
        
    return result
