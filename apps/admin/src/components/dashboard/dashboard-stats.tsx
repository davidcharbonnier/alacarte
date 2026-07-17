import { Box, Card, CardActionArea, CardContent, Skeleton, Typography } from '@mui/material';
import People from '@mui/icons-material/People';
import ArrowForward from '@mui/icons-material/ArrowForward';
import { useQuery } from '@tanstack/react-query';
import { Link } from '@tanstack/react-router';
import { useSchemaContext } from '../../lib/context/schema-context';
import { dynamicItemApi } from '../../lib/api/schema-api';
import { userApi } from '../../lib/api/users';
import { ItemTypeCard } from './item-type-card';

export function DashboardStats() {
  const { schemas } = useSchemaContext();

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
      <Box
        sx={{
          display: 'grid',
          gridTemplateColumns: { xs: '1fr', md: 'repeat(2, 1fr)', lg: 'repeat(3, 1fr)' },
          gap: 2.5,
        }}
      >
        {schemas.map((schema) => (
          <ItemTypeStatCard key={schema.name} schema={schema} />
        ))}
      </Box>
      <UserStatCard />
    </Box>
  );
}

function ItemTypeStatCard({ schema }: { schema: any }) {
  const { data, isLoading } = useQuery({
    queryKey: [schema.name, 'list'],
    queryFn: () => dynamicItemApi.list(schema.name),
  });

  return (
    <ItemTypeCard
      itemType={schema.name}
      displayName={schema.plural_name}
      icon={schema.icon}
      color={schema.color}
      totalItems={data?.total || 0}
      isLoading={isLoading}
    />
  );
}

function UserStatCard() {
  const { data: users, isLoading } = useQuery({
    queryKey: ['users', 'list'],
    queryFn: () => userApi.getAll(),
  });

  return (
    <Card>
      <CardActionArea component={Link} to="/users">
        <CardContent sx={{ p: 3 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2.5 }}>
            <Box
              sx={{
                width: 56,
                height: 56,
                borderRadius: '16px',
                bgcolor: 'primaryContainer',
                color: 'onPrimaryContainer',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <People sx={{ fontSize: 28 }} />
            </Box>
            <Box sx={{ flex: 1 }}>
              <Typography variant="titleMedium" sx={{ mb: 0.5 }}>
                Users
              </Typography>
              {isLoading ? (
                <Skeleton width={120} />
              ) : (
                <>
                  <Typography variant="body2" color="onSurfaceVariant">
                    {users?.length || 0} {users?.length === 1 ? 'user' : 'users'} in database
                  </Typography>
                  <Typography variant="labelLarge" color="primary" sx={{ mt: 0.5 }}>
                    View all users
                  </Typography>
                </>
              )}
            </Box>
            <ArrowForward sx={{ color: 'onSurfaceVariant' }} />
          </Box>
        </CardContent>
      </CardActionArea>
    </Card>
  );
}
