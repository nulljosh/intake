import { useState, useEffect } from 'react';
import { spark } from '../lib/spark';
import { useAuth } from '../context/AuthContext';

const EMPTY_PROFILE = { substances: [], conditions: [], pendingTests: [], notes: '' };

export function useProfile() {
  const { user } = useAuth();
  const [profile, setProfile] = useState(EMPTY_PROFILE);
  const [profileLoading, setProfileLoading] = useState(true);

  useEffect(() => {
    if (!user) return;

    spark
      .from('dose_profiles')
      .select('data')
      .eq('id', user.id)
      .single()
      .then(async ({ data, error }) => {
        if (error || !data) {
          await spark.from('dose_profiles').insert({ id: user.id, data: EMPTY_PROFILE });
          setProfile(EMPTY_PROFILE);
        } else {
          setProfile(data.data);
        }
        setProfileLoading(false);
      });
  }, [user]);

  async function saveProfile(next) {
    setProfile(next);
    await spark
      .from('dose_profiles')
      .upsert({ id: user.id, data: next, updated_at: new Date().toISOString() });
  }

  return { profile, saveProfile, profileLoading };
}
