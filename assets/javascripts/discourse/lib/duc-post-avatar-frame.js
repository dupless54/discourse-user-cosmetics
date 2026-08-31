export const POST_AVATAR_FRAME_CLASS_PREFIX = "duc-avatar-frame-user-";

export function postAvatarFrameClassTransformer({ value, context }) {
  const userId = context?.post?.user_id ?? context?.user?.id;
  if (userId === undefined || userId === null) {
    return value;
  }

  const className = `${POST_AVATAR_FRAME_CLASS_PREFIX}${userId}`;
  if (!value.includes(className)) {
    value.push(className);
  }

  return value;
}
