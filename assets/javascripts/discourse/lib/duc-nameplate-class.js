export const POST_NAMEPLATE_CLASS_PREFIX = "duc-nameplate-post-user-";
export const MENTION_NAMEPLATE_CLASS_PREFIX = "duc-nameplate-mention-user-";

function addUserClass(value, userId, prefix) {
  if (userId === undefined || userId === null) {
    return value;
  }

  const className = `${prefix}${userId}`;
  if (!value.includes(className)) {
    value.push(className);
  }

  return value;
}

export function postNameplateClassTransformer({ value, context }) {
  const userId = context?.user?.id ?? context?.post?.user_id;
  return addUserClass(value, userId, POST_NAMEPLATE_CLASS_PREFIX);
}

export function mentionNameplateClassTransformer({ value, context }) {
  return addUserClass(
    value,
    context?.user?.id,
    MENTION_NAMEPLATE_CLASS_PREFIX
  );
}
